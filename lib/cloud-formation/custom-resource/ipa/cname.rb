require 'cloud-formation/custom-resource/base-handler'

module CloudFormation
  module CustomResource
    module IPA
      class CNAME < CloudFormation::CustomResource::BaseHandler

        # This class is build to handle th IPA-CNAME custom resourc
        # The following line will ensure that the class gets
        # registered as the handler for the IPA-CNAME custom resource
        # in the default router.
        resource_types 'Custom::IPA-CNAME'

        # The IPA-CNAME resoure must be told what its Zone, RecordName
        # and HostName are. The following sets up some automatic logic
        # to fail resource requests if they do not provide information
        # for these parameters.
        mandatory_parameters *%w(Zone RecordName HostName)

        def initialize *args
          super *args
        end


        # All of the actions that we will be performing for allocating
        # these resources will require for the handler to obtain kerberos
        # credentials. The method below sets up a kerberos context
        # and then runs its block, and tears down the context after the
        # block is done.

        # The keytab and principal to use for the kerberos context should
        # be identified in the router's global configuration by the keys
        # cname-keytab and cname-principal
        def with_kerberos_tickets
          begin
            keytab = config['cname-keytab']
            principal = config['cname-principal']

            ENV['KRB5CCNAME'] = "/tmp/krb-#{requestId}"
            system("kinit -kt #{keytab} #{principal}")
            unless $?.to_i == 0
              return fail! "IPA CNAME Handler error: unable to obtain kerberos credentials. keytab: #{keytab}, principal: #{principal}"
            end

            return yield
          rescue Exception => m
            fail! m.inspect
          ensure
            ENV['KRB5CCNAME'] = "/tmp/krb-#{requestId}"
            system("kdestroy")
          end
        end

        # ipa dnsrecord-add does curious things when the recordname
        # already exists. We do not want to let people accidentally
        # configure dns round-robin cnames, so instead we are going
        # to fail a request to create a cname if there is already
        # any kind of dns record for the given name.
        def ipa_check_for_record properties
          # Returns true if the zone already has an entry for recordname
          zone, record, hostname = ['Zone', 'RecordName'].map { |x| properties[x] }
          ENV['KRB5CCNAME'] = "/tmp/krb-#{requestId}"
          `ipa dnsrecord-find #{zone} #{record}`
          return $?.to_i == 0
        end

        def ipa_dns_cname_record action, properties
          zone, record, hostname = ['Zone', 'RecordName', 'HostName'].map { |x| properties[x] }
          ENV['KRB5CCNAME'] = "/tmp/krb-#{requestId}"
          self.reason = `ipa dnsrecord-#{action} #{zone} #{record} --cname-rec=#{hostname}`
          return $?.to_i == 0
        end

        def create(properties)
          unless validate!(properties)
            return false
          end

          self.physicalId = "cname-#{properties['RecordName']}.#{properties['Zone']}"

          with_kerberos_tickets do
            if ipa_check_for_record(properties)
              fail! "DNS Entry #{properties['RecordName']}.#{properties['Zone']} alreay exists."
            else
              ipa_dns_cname_record('add', properties)
            end
          end
        end

        def delete(properties)
          unless validate!(properties)
            return false
          end

          # If for some reason a Create request fails, we will
          # eventually be getting a corresponding delete request. One
          # of the ways that a create could fail is if the cname
          # record already exists, in which case, we should not be
          # deleting it.

          # Failed create requests get assigned a physical resource id
          # by cloudformation, and will not look like the physical
          # resource ids generated by a properly created resource.

          # We should only try to delete ipa records if the physical
          # resource id is in the format that we set.

          unless self.physicalId =~ /^cname-/
            return true
          end

          with_kerberos_tickets do
            ipa_dns_cname_record('del', properties)
          end

          # Most likely, any failure was because the record
          # did not exists, so dont pass the failure on.
          true
        end

        def update(new_properties, old_properties)
          unless validate!(new_properties)
            return false
          end

          unless validate!(old_properties)
            return false
          end

          if new_properties['Zone'] == old_properties['Zone'] &&
              new_properties['RecordName'] == old_properties['RecordName']
            # If the Zone and RecordName have not changed, then we
            # can just issue a dnsrecord-mod
            with_kerberos_tickets do
              ipa_dns_cname_record('mod', new_properties)
            end
          else
            with_kerberos_tickets do
              ipa_dns_cname_record('del', old_properties)
              ipa_dns_cname_record('add', new_properties)
            end
          end
        end
      end
    end
  end
end
