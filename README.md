# cfn-custom-resource

This gem handles much of the heavy lifting around handling requests for cloudformation custom resources.

## Defining your own custom resource

Generally, to start handling your own custom resources, you define a
class derived from CloudFormation::CustomResource::BaseHandler that
declares which custom resource types it handles and which implements
the create, delete and update methods, as below.

```ruby
class MyCustomResource < CloudFormation::CustomResource::BaseHandler

  resource_types 'Custom::MyResource'

  def create(properties)
    self.physicalId = "myResource1"
    self.data = { "one" => "1", "two" => "2" }
    return true
  end

  def delete(properties)
    return true
  end

  def update(properties, old_properties)
    self.fail! "Updates are not allowed"
  end
```

The "resource_types" declaration will register your class as the
handler for the listed resource types with the default router.

The properties passed to your create, delete and update actions come
from the properties defined in the custom cloudformation resource
declaration. In the case of an update, you get both the new resource
properties and the old resource properties.

When creating resources, you MUST assign the new resource a physical id,
or cloudformation will not recognize your success message.

Whenever a create, update or delete action fails, it needs to ensure that
the "Reason" field of the response object is set. The "fail!" method does
this for you.

## Configuration

You can set up some top level configuration on the default router that
will get passed to the handler objects.

```ruby
CloudFormation::CustomResource::Router.default_router.config = { :stuff => "here" }
```

## Validation

CloudFormation::CustomResource::BaseHandler includes some helper
functionality for validating resource propertiess. These methods are
not called by default, so if you do not want property validation, you
can simply not call the validation methods in your action methods.

```ruby
class MyCustomResource < CloudFormation::CustomResource::BaseHandler

  resource_types 'Custom::MyResource'

  mandatory_parameters 'A', 'B'
  optional_parameters 'C', 'D'

  def create(properties)
    return false unless validate(properties)

    self.physicalId = "myResource1"
    self.data = { "one" => "1", "two" => "2" }
    return true
  end

  def delete(properties)
    return true
  end

  def update(properties, old_properties)
    return false unless validate(properties)

    self.fail! "Updates are not allowed"
  end
```

The above class will check that both properties 'A' and 'B' are
present, will allow properties 'C' and 'D', but will fail if any other
properties are given. When validation fails, it sets the "Reason"
field for you.

## Sending responses

Here is a typical snippet of code from a hander server

```
# request contains an object from
handler = CloudFormation::CustomResource::Router.default_router.get_handler(request)
handler.process_request
handler.send_response!
```

## Caution with Deletes

Deletes need to be treated with some special care. There are a couple
important cases that needd to be handled specially. First, it is
important to remember that whenever a create or an update fails, it
will soon be followed by a delete message. In the case of a failed
create, it is possible (likely) that the un-created resource will be
given an automatically generated physical id. Second, if a delete
action fails, it will usually leave the associated stack in an
unfriendly state like "DELETE_FAILED" or "ROLLBACK_FAILED", both of
which require some manual intervention to recover from.

Imagine a resource that needs to have a unique name when it is
created. The create action looks to see if named resource already
exists when it is created returns a FAILED status when it tries to
create a resource that previously existed. Clouformation will then
turn around with a Delete request for the same resource. If we blindly
use the requested properties to delete the alreay-existing resource,
we will have deleted a resource that some other entity owns. To keep
this from happening, the handler should ensure that there is some link
between the physical id and the actual resource to be deleted. In some
cases, the right thing to do will be to not actually delete anything,
and report to AWS that the action was successful.

## Not Part of this Gem

This gem does not handle anything about ensuring that it actually gets the request
objects from AWS. It will be up to you to either

1) Set up an SNS topic, set up an HTTP server to handle SNS topic notifications, register
the server with the topic, etc. In this case, when an HTTP request comes in with
a custom resource request, the http server passes the request object on to the router
to create a hander and uses it to send the response.

2) Set up an SNS topic. Set up an SQS queue. Register the queue as and endpoint with the SNS
topic. Create a queue processor that wathes the queue for incoming requests. When they arrive,
the queue processor hands them off to the router to get a handler, and uses that to send
a response.

Note that in both cases, the arn for the SNS topic in queestion will need to be communicated
to whatever entity is requesting Custom Resources through cloudformation. In the latter case,
the queue polling servers will need to know the details of the created queue.
