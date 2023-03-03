# Neovim Configuration

This is my personal neovim configuration that I use for programming, documenting and pretty much any text file editing or development task that requires manipulating text based files.


## Installation

TODO install nvim

### preservim / vim-markdown

Plugin for markdown preview

Before adding preservim/vim-markdown do

	git clone https://github.com/preservim/vim-markdown.git
	cd vim-markdown
	sudo make install
	vim-addon-manager install markdown

Then add the plugin:

### Java Language Server

Use 'jdtls' from eclipse. To install follow this [video](https://www.youtube.com/watch?v=94IU4cBdhfM). Similar configuration is explained in the plugin page for using [jdtls with nvim](https://github.com/mfussenegger/nvim-jdtls)






# AMC Deployer  

## Main classes
TODO add links to classes in GitHub

**[DeploymentTypesConfiguration](https://github.com/mulesoft/amc-deployer/blob/master/amc-deployer-service/src/main/java/com/mulesoft/amc/deployer/clients/registry/model/DeploymentTypesConfiguration.java)** 

Configuration for each deployment type as defined in [atlas](https://github.com/mulesoft/amc-atlas/blob/master/src/main/resources/types/providers/providerTypes.yml)

**[TargetProvider](https://github.com/mulesoft/amc-deployer/blob/master/amc-deployer-service/src/main/java/com/mulesoft/amc/deployer/model/domain/TargetProvider.java)**

Target providers as defined in [atlas](https://github.com/mulesoft/amc-atlas/blob/master/src/main/resources/types/providers/providerTypes.yml) but harcoded as an Enum class.
Possible targets are:
* MC: Mule cloud - Used for Runtime Fabric deployment (RTF on-prem, CH 2.0). Most common deployment types are: Mule application, Edge, EdgeConfig, PoseidonAgent (Runtime Fabric agent), Tokenizer.
* IP: Infra provisioner - Used to provision infrastructure in runtime fabric (mainly private spaces). Most common deployment types are: Network, Cluster
* RR: Runtime Remote - Used for standalone runtimes in hybrid. Only for Flex Gateways.

**[TargetInfo](https://github.com/mulesoft/amc-deployer/blob/master/amc-deployer-service/src/main/java/com/mulesoft/amc/deployer/clients/registry/model/TargetInfo.java)**

The target is the actual runtime plane in which a deployment is going to be done. Deployments have a reference to the target runtime plane based on their targetId, targetProvider code (MC, IP, RR), orgId and (optional) envId. 

Properties:
* id 
* type
* availability: status which can be AVAILABLE, UNAVAILABLE, MAINTENANCE_MODE
* Set<NodeInfo> nodes: Each node that can be used for deployment with id, location (word location, string), isAvailableForDeployments, availability ()
* defaults: Defaults per deployment type
* List<Runtime> runtimes: runtimes (and their versions) supported by the target
* replicationStrategies 
* featureFlags: target feature flags - not all targets support all features.

**[Spec](https://github.com/mulesoft/amc-deployer/blob/9c38537f72a3e0e4042cbc0042bd61bc94dac164/amc-deployer-service/src/main/java/com/mulesoft/amc/deployer/model/domain/Spec.java)**

Defines a deployment specification. Each time an update (add, delete, update) to a deployment is made, it's done by sending a new desired state represented by an Spec object.



## Components interaction

### Deployment
```plantuml
@startuml
skinparam maxMessageSize 20

Client ->> AMCDeployerAPI : PATCH /deployments/{deploymentId}
AMCDeployerAPI ->> AMCDeployer
AMCDeployer ->> AMCAtlasAPI: GET /api/v2\n/organizations/{orgId}\n/providers/{targetProviderCode}\n/targets/{targetId}
note right: Apply decorations \nfor secrets and \nasset references
box "HTTP API"
  participant AMCDecoratorAPI #lightblue
end box
alt changeSpec?
 AMCDeployer ->> AMCDecoratorAPI : HTTP /specs/{version}/framework - processSpec(DeploymentSpecDTO) : ProcessedSpecDTO 
end

alt changeSpec || changeSpecVersion
  AMCDeloyer ->> Deployment : updateReplicas
end

box "QuotasBroker"
  participant quotas.Deployments #FF5733
end box
alt updatedDeployment.specVersion != previousSpecVersion && shouldTriggerPipeline (always true)
  AMCDeployer ->> quotas.Deployments : PipelineRequestMessage - quotas.Deployments
end

QuotasBroker ->> AMCQuotas : quotas.Deployments

box "QuotasBroker"
  participant quotas.DeploymentsReport #FF5733
end box

box "QuotasBroker"
  participant quotas.Reports #FF5733
end box

alt if operationType.delete

  AMCQuotas ->> quotas.DeploymentsReport : Deployment.APPROVED 
  note left: deletes all stored \nreports for the \ndeployment and sends \ndirectly an approval.

else if no reports to be applied to the deployment 

  AMCQuotas ->> quotas.DeploymentsReport : Deployment.APPROVED 

else if scripting error processing report 

  AMCQuotas ->> quotas.DeploymentsReport : Deployment.REJECTED 

else 

  alt if operationType.Sync

    AMCQuotas ->> AMCQuotas : Filter reports by reportsName input.
    note right: There's an input \nparam for SYNC \nwhich are the set \nof reports to process.

  end
  
  loop for each report

    AMCQuotas ->> quotas.Reports : send reports to process

  end

end

quotas.Reports ->> AMCQuotas : ReportProcessMessage

alt operationType.SYNC

  AMCQuotas ->> AMCQuotas : report.setStatus(APPROVED)

else 

  alt report has LimitProvider
    box "HTTP API"
      participant LimitProviderAPI #lightblue
    end box
    AMCQuotas ->> LimitProviderAPI : getLimit

    alt usage within limits of deployment request

      AMCQuotas ->> AMCQuotas : report.setStatus(APPROVED)
    else 

      AMCQuotas ->> AMCQuotas : report.setStatus(REJECTED)
    end

  end
  
end

box "QuotasBroker"
 participant quotas.Status #FF5733 
end box
AMCQuotas ->> quotas.Status : report

quotas.Status ->> AMCQuotas : ReportProcessMessage
AMCQuotas ->> AMCQuotas : update ReportProgressResult with ReportProcessMessage and storage

alt if ReportProgressResult.isComplete

  AMCQuotas ->> AMCQuotas : select nodes to use for deployment

  alt if (there are reports without node rejected OR (not enough nodes available AND at least one report by node))

    AMCQuotas ->> AMCQuotas : ReportProcessMessage.setStatus(REJECTED)

  else 

    AMCQuotas ->> AMCQuotas : ReportProgressResult.setStatus(APPROVED)

  end

  AMCQuotas ->> quotas.DeploymentsReport : Deployment(ReportProgressResult.getStatus())
  
else 

  AMCQuotas ->> AMCQuotas : update progress 

end

quotas.DeploymentsReport ->> AMCDeployer : Deployment Status

box "Decorator Broker"
  participant decorator.SpecDecorationRequest #FF5733
end box

box "Transport Layer Broker"
  participant "{nodeInfo.location}.Provider\n.{target.provider.code}.Agent\n.{nodeInfo.id}.State" as transportLayer 
  note left : TODO translate parameters to actual meaning.
end box

alt if decoration feature enabled 

  
  AMCDeployer ->> decorator.SpecDecorationRequest : SpecDecorationRequest


else 

  loop for each node to deploy 
    AMCDeployer ->> transportLayer : node deployment message (DeploymentMessage) 
  end

end

@enduml
```
Questions: 
 * In the diagram above there's an update in the deployment and the specVersion may have change. Examples of changes in a specVersion and how it can affect a deployment?
<!--toc:start-->

- [AMC Deploy - Sequence diagrams](#amc-deploy-sequence-diagrams)
  - [Deployment Update](#deployment-update)
  <!--toc:end-->

## Decoration Process

Description: This is the entire process for decorating a specification. A request is sent to queue spec.SpecDecorationRequest in the Decorator Broker TODO complete

```plantuml

@startuml
skinparam maxMessageSize 20 

box "Decorator Broker"
  participant decorator.SpecDecorationRequest #FF5733
end box
participant AMCDecorator
box "HTTP API"
  participant AtlasAPI #lightblue
end box
box "Decorator Broker"
  participant decorator.SpecDecorationResult #FF5733
end box
box "Decorator Broker"
  participant decorator.SpecDecorationProviderRequest #FF5733
end box
box "Decoration Broker"
  participant decorator.SpecDecorationProgress #FF5733
end box
box "HTTP API"
  participant DecorationProviderAPI #lightblue
end box
box "HTTP API"
  participant CSMAPI #lightblue
end box
box "Decoration Broker"
  participant decorator.DeployDestroy #FF5733
end box

== Decoration Process - Start ==
decorator.SpecDecorationRequest ->> AMCDecorator: send(PipelineRequestMessage)
alt OperationType is UPSERT

  AMCDecorator ->> AtlasAPI : fetch decorations configuration 
  note left: The decoration \nconfigurations rules \n(see [[ttps://github.com/mulesoft/amc-atlas/blob/master/src/main/resources/decorators/decorators.yml decorators.yml]]) \ngets applied \nto the spec \nand those that \nmatch are the \ndecorations that \nmust be applied. \nThere are \nmany decorations \nby decorator name.

  alt if decoration progress decorations by decorator is empty
    AMCDecorator ->> decorator.SpecDecorationResult : send(new SpecDecorationResult(.., DecorationResult.SUCCESSFUL, ..))
  else if there are decorations by decorator
    loop for each decoration to do
      AMCDecorator ->> decorator.SpecDecorationProviderRequest: send(new SpecDecorationProviderRequest(..))
    end
  end

else if OperationType is DELETE
  AMCDecorator ->> AMCDecorator: fetch SECRET type decorations stored 
  note right #lightgreen: This seems \nnot to \nextensible. This is \nassuming that only \nthe SECRET type \ndecorations will require \ndeletion. This \nshould probable be \nmade more generic \nand the decoration \nshould declare \nif it requires \ndeletion or not.
  alt if there are no decorations

    AMCDecorator ->> decorator.SpecDecorationProgress : send(new SpecDecorationProgress(.., DecorationStatus.SUCCESSFUL,.. ))
  else if there are decorations
    AMCDecorator ->> decorator.SpecDecorationProviderRequest : send(new SpecDecorationProviderRequest(.., OperationType.DELETE, ..))  
  end

else if OperationType is SYNC
    AMCDecorator ->> decorator.SpecDecorationProgress : send(new SpecDecorationProgress(.., DecorationStatus.SUCCESSFUL,.. ))
    note left: nothing to do \nwe just send a success \nresult.
end

== Decoration Process - Decoration Provider Request ==
decorator.SpecDecorationProviderRequest ->> AMCDecorator: send(DecorationProcessMessage)

alt OperationType is UPSERT
  alt if all stored decorations are DecorationStatus.SUCCESSUL
    AMCDecorator ->> decorator.SpecDecorationProgress : send(new SpecDecorationProgress(.., DecorationStatus.SUCCESSUL, ..))
    note left: A successful \nmessage is sent \nfor the decorations \nof this decoration \nprovider. \nTODO review why this \ncase could happen.
  else if decorations hasn't being execute by the provider
    AMCDecorator ->> DecorationProviderAPI : GET /{endpoint}     
    note right #lightgreen: {endpoint} it's \ndefined in Atlas \n[[https://github.com/mulesoft/amc-atlas/blob/60d5c5dd8e0c4ec1c525e2d09af823808a9add4e/src/main/resources/decorators/decorators.yml#L62 decorator configuration]].
    alt if all decorations are successful
      AMCDecorator ->> decorator.SpecDecorationProgress: send(new SpecDecorationProgress(.., DecorationStatus.SUCCESSUL, ..))
    else if there are failed decorations
      AMCDecorator ->> decorator.SpecDecorationProgress: send(new SpecDecorationProgress(.., DecorationStatus.FAILED, ..))
    end
  end
else OperationType is DELETE
  loop for each secret decoration
    AMCDecorator ->> CSMAPI: DELETE /secrets-manager\n/internal/api/v1\n/organizations/{orgId}\n/environments/{envId}\n/clients/{clientId}\n/secretsGroup/{secretGroupId}\n/sharedSecrets/  
    note right: environtments/{envId} \nis optional given\n that the secret \nmay not be related \nto an env.
  end loop
  AMCDecorator ->> decorator.SpecDecorationProgress: send(new SpecDecorationProgress(.., DecorationStatus.SUCCESSUL, ..))
end

== Decoration Process - Process Decoration Provider Results ==

decorator.SpecDecorationProgress ->> AMCDeployer: send(DecorationProgressMessage)

alt if OperationType.UPSERT
  AMCDecorator ->> AMCDecorator: retrieve all decorations
  alt if decorations continues in progress or decorations deleted
    AMCDecorator ->> AMCDecorator: process finishes here and the progress message is diregarded
  else decorations results are complete
    alt if all decorations progress are success
     AMCDecorator ->> decorator.SpecDecorationResult: send(new SpecDecorationResult(.., DecorationStatus.SUCCESSUL,.. )) 
    else if there are failure decorations progress
     AMCDecorator ->> decorator.SpecDecorationResult: send(new SpecDecorationResult(.., DecorationStatus.FAILURE,.. )) 
    end
  end
else if OperationType.DELETE
  alt if decoration progress is successful
    AMCDeployer ->> AMCDeployer: delete decorations from DB
    note right: Deleting secrets \nafter successfully \ndeleted them \n from CSM
  end
  alt if there's not secrets pending to be deleted
    AMCDeployer ->> AMCDeployer: delete all decorations for this deployment
  end
  AMCDeployer ->> AMCDeployer: retrieve DecorationProgress from DB
  alt there is no DecorationProgress stored 
    AMCDeployer ->> AMCDeployer: finish process, deletion already happened 
  else  there is DecorationProgress stored
    alt DecorationProgress.type is DESTROY
      AMCDeployer ->> decorator.DeployReply: send(new DestroyMessage(..))
    else
      AMCDeployer ->> decorator.SpecDecorationResult: send(new DecorationResult(DecorationStatus.SUCCESSUL))
    end
  end
end


@enduml

```


## AMC Deployer sequence diagrams

### Deployment Update - API Endpoint

API: [PATCH /deployments/{deploymentId}]
From:

- AMC Deployer - DeploymentServiceTest.concurrencyExceptionOnRepositoryShouldBeCaught

```plantuml

@startuml
skinparam maxMessageSize 20
box "HTTP Client"
  actor Client #lightblue
end box
Client ->> DeploymentService : update(deploymentId, DeploymentUpdateRequest)\n PATCH /deploymenys/{deploymentId
DeploymentService ->> DeploymentRepository : get(deploymentId) : Deployment
DeploymentService ->> DeploymentService : update(Deployment, DeploymentUpdateRequest, shouldTriggerPipeline)

group within update(..)
DeploymentService ->> TargetRegistry : getTarget(orgId, targetProviderCode, targetId, envId?) : TargetInfo
TargetRegistry ->> AtlasClient: getTarget(orgId, wtProviderCode, targetId, envId?) : TargetInfo
box "HTTP API"
  participant AtlasAPI #lightblue
end box
AtlasClient ->> AtlasAPI : GET /api/v1\n/organizations/{orgId}\n/providers/{targetProviderCode}\n/targets/{targetId} 
DeploymentService ->> TargetService : checkTargetAvailability\n(deploymentType, target, targetProviderCode)
TargetService ->> TypeConfiguration : getConfiguration(deploymentType) : DeploymentTypeConfiguration
TargetService ->> TargetService : isRequireAvailability && !DeploymentTypeConfiguration.isAvailableForDeployments
note right : in mule cloud checks if there's at least a region available

alt if changeSpec

  DeploymentService ->> DeploymentService : updateSpec(Deployment, DeploymentUpdateRequest, TargetInfo)
  DeploymentService ->> SpecProcessor : update(Deployment, updateRequest.getSpec(), TargetInfo?) : Spec
  note right: creates  a spec and validates the spec from \nAMC or AMF

  alt if decoratorIntegrationEnabled

  SpecProcessor ->> DecoratorClient : getProcessedSpec(DeploymentSpecDTO)
  DecoratorClient ->> DecoratorClient : performRequest(url, Object:DeploymentSpecDTO):ProcessedSpecDTO
  box "HTTP API"
  participant AMCDecorator #lightblue
  end box
  DecoratorClient ->> AMCDecorator: HTTP /specs/{version}/framework
  SpecProcessor ->> ConfigurationProcessor : getConfigurationWithoutAssets\n(DeploymentAssetType.CONFIGURATION, ProcessedSpecDTO.\ngetConfigurationWithoutSecrets())
  note left : Deploymnet.setSpec(Spec) - updates deployment spec.

  end

end

alt if changeSpec || changeSpecVersion
    DeploymentService ->> DeploymentService : Deployment.updateReplicas()
    DeploymentService ->> DeploymentRepository : save(Deployment)
end

alt if updatedDeployment.specVersion != prevVersion && shouldTriggerPipeline (always true)
  DeploymentService ->> TargetService : getReplicationStrategy\n(Deployment.getType(), Deployment.getTargetProvider().getCode(), TargetInfo): strategy
  DeploymentService ->> BrokerPublisherWrapper : buildAndQueueDeployment\nReportMessagesWithStrategy(Deployment, OperationType.UPSERT, strategy)
  note right : Builds and queues the messages for deployment to the \nQuotasBroker.
  BrokerPublisherWrapper ->> QuotasMessageFactory : buildPipelineRequestMessage\n(Deployment, OperationType.Upsert, nodesIds, strategy)
  group within buildPipeline..
    QuotasMessageFactory ->> QuotasRequestMessage : new(..) : QuotasMessageRequest
    QuotasMessageFactory ->> BrokerMessage : quotas("quotas.Deployments", \nQuotasMessageRequest, ..) : BrokerMessage<PipelineRequestMessage>
  end
  BrokerPublisherWrapper ->> BrokerPublisher : publish(BrokerMessage<PipelineRequestMessage>)
  box "Quotas Broker\nquotas.Deployments"
    participant QuotasBroker #FF5733
  end box
  BrokerPublisher ->> QuotasBroker : publish(..) quotas.Deployments
end

end

@enduml
```

### Process message back from quotas - JMS Listener

JMS Broker: Quotas ; queue: quotas.DeploymentsReport
Description: Deployer Process messages coming from quotas to move deployment to next phase or update the deployment if it was rejected.

```plantuml

@startuml
skinparam maxMessageSize 20
box "Quotas Broker\nquotas.DeploymentsReport"
actor Client #FF5733
end box
skinparam maxMessageSize 20
participant "BrokerService" as bs
Client ->> bs : quotas.DeploymentReport
bs ->> QuotasBrokerSubscriber : processAsDeployerMessagesBackFromQuotas(\nTextMessage)
note right: TextMessage gets  transformed to  QuotasReplyNotification
QuotasBrokerSubscriber ->> DeploymentService : findByIdAndFetchSpecs(QuotasReplyNotification.getDeploymentId())\n:Deployment

alt QuotasReplyNotification.getStatus().equals(APPROVED)
  QuotasBrokerSubscriber ->> DeploymentService : updateReplicasForSelectedNodes(Deployment, QuotasReplyNotification.getNodes())
  note left: It's not directly QuotasReplyNotification.getNodes() but a curated list

  alt if decoratorFeatureEnabled
    QuotasBrokerSubscriber ->> DecoratorMessageFactory : buildSpecDecorationRequestMessage(Deployment, QuotasReplyNotification.getOperationType()):\nBrokerMessage\n<PipelineRequestMessage>
    DecoratorMessageFactory ->> PipelineMessageUtils : transformDeploymentReportInformation(Deployment, includeFeatureFlags = true) : DeploymentReportInformation
    
    alt includeFeatureFlags
      
      PipelineMessageUtils ->> TargetService : getTargetInfo(Deployment) : TargetInfo
      PipelineMessageUtils ->> PipelineMessageUtils : targetFeatureFlags = TargetInfo.featureFlags
      note right #lightgreen: Review feature flags usage per target when making UMP a platform

    end 

    DecoratorMessageFactory ->> PipelineRequestMessage : new(Deployment.id, DeploymentReportInformation)
    DecoratorMessageFactory ->> QuotasBrokerSubscriber : BrokerMessage<PipelineRequestMessage>
    QuotasBrokerSubscriber ->> BrokerPublisher : publish(BrokerMessage)
    note right: Builds a pipeline request message to start our \ndeployment pipeline.
    box "decorator.SpecDecorationRequest"
      participant DecoratorBroker #FF5733
    end box
    BrokerPublisher ->> DecoratorBroker : send(BrokerMessage) decorator.SpecDecorationRequest

  else

    QuotasBrokerSubscriber ->> DeploymentsMessageFactory : buildMessagesForDeploymentAndSpec(Deployment, QuotasReplyNotification.getSpecVersion(), \nQuotasReplyNotification\n.getSelectedNodes())
    DeploymentsMessageFactory ->> QuotasBrokerSubscriber : List<BrokerMessage\n<DeploymentMessage>> 

    QuotasBrokerSubscriber ->> BrokerPublisher : publish(\nList<BrokerMessage<DeploymentMessage>>) 
    box "{nodeInfo.location}.Provider.\n{target.provider.code}.\nAgent.{nodeInfo.id}.State"
      participant "TransportLayerBroker" #FF5733
    end box
    BrokerPublisher ->> TransportLayerBroker : publish each deployment message
    note right: One message \nper node is sent \nto the target to \nexecute the deployment
    QuotasBrokerSubscriber ->> BrokerPublisher : publish(BrokerMessage)
    note right: Build transport messages for a deployment \nand each node \nof its target.

  end


@enduml

```

TODO add link between both diagrams

```plantuml

@startuml
    Client ->> DeploymentsMessageFactory : buildMessagesFor\nDeploymentAndSpec\n(Deployment, specVersion, selectedNodes)
    DeploymentsMessageFactory ->> TargetService : getTargetInfo(Deployment) : TargetInfo
    DeploymentsMessageFactory ->> DeploymentsMessageFactory : buildMessagesForDeployment\nSpecAndTarget(Deployment, \nDeployment.getSpec(Deployment.specVersion) \nas spec, TargetInfo, \nDeployment.nodeIds) : List<BrokerMessage<DeploymentMessage>>
    DeploymentsMessageFactory ->> DeploymentsMessageFactory : getDeploymentMessageContent\n(Deployment, \nspec, TargetInfo) \n: DeploymentMessageContent
    DeploymentsMessageFactory ->> DecoratedSpecFactory : \ngetDecoratedSpec(\nDeployment.type, \nDeployment.name, \ndeployment.targetProvider.code, spec)\n: DecoratedSpec 

    alt decoratorIntegrationEnabled

      DeploymentsMessageFactory ->> DecoratorService : getDecoratedSpecFromDecorator(\nDeployment, spec, \nDecorationVisibility.ALL)\n: DecoratedSpecDTO
      DecoratorService ->> DecoratedSpecRequestDTO : new(..)
      DecoratorService ->> DecoratorClient : getDecoratedSpec(\nDecoratedSpecRequestDTO): \nDecoratedSpecDTO
      box "HTTP API"
        participant AMCDecoratorAPI #lightblue
      end box
      DecoratorClient ->> AMCDecoratorAPI : /spec/{version}: DecoratorSpecDTO 
      note right: Retrieves a spec \nalready decorated
    end

    DeploymentsMessageFactory ->> TargetInfo : getNodes() : Set<NodeInfo>

    DeploymentsMessageFactory ->> DeploymentsMessageFactory : availableNodes = Set<NodeInfo> filter by Deployment.nodeIDs

    alt optimizedFlexMessagePublication AND Deployment is in standalone 

      DeploymentsMessageFactory ->> DeploymentsMessageFactory : availableNodes = filter availableNodes which DeploymentState != APPLIED
      
      note right #lightgreen: Feature flag specific for flex to avoid publishing messages to nodes which the deployment is already applied

    end

    loop availableNodes : nodeInfo 

      DeploymentsMessageFactory ->> DeploymentsMessageFactory : buildMessageForNode\n(Deployment, TargetInfo, \nnodeInfo, spec, DeploymentMessageContent, \nTargetInfo.enhancedSecurity)

    end

    DeploymentsMessageFactory ->> Client : List<BrokerMessage\n<DeploymentMessage>> 

@enduml

```

### BrokerPublisher - JMS message sender

Description: Builds and queues the messages for deployment. Based on the list of input messages it will introspect each message and send the message to different brokers / queues. All JMS messages are sent through this class.

``` mermaid
sequenceDiagram
  participant Client
  box rgb(255,87,51) 
    participant AnyBroker 
  end
  Client ->> BrokerPublisher: publish(List<BrokerMessage<T>>)
  loop List<BrokerMessage<T>>
    BrokerPublish ->> BrokerPublisher : processMessage(BrokerMessage<T>)
    note right of BrokerPublisher: uses logic for retry
    BrokerPublish ->> BrokerPublish : send(BrokerMessage<T>)
    BrokerPublish ->> MapOfBrokerToJmsTemplate : get(BrokerMessage.getBroker()) : JmsTemplate
    BrokerPulish ->> JmsTemplate : execute(..)
    note right of JmsTemplate: Creates JMS message andsends it.
    JmsTemplate ->> AnyBroker : publishMessage(..)
  end

```

MapOfBrokerToJmsTemplate is actually a Map<Broker, JmsTemplate> and gets created using this code in BrokerPublisher constructor:

```java
brokersJmsTemplates.put(TRANSPORT_LAYER, transportLayerJmsTemplate);
brokersJmsTemplates.put(NOTIFICATION_BUS, notificationBusJmsTemplate);
brokersJmsTemplates.put(QUOTAS_BROKER, quotasJmsTemplate);
brokersJmsTemplates.put(DECORATOR_BROKER, decoratorJmsTemplate);
```

Configuration values are obtained from `application.yml` file which gets configured by env properties.

### Get TargetInfo 

```plantuml

@startuml
skinparam maxMessageSize 20 
actor Client
Client ->> TargetService : getTargetInfo(orgId, targetProvider, targetId) : TargetInfo
TargetService ->> AtlasClient : getTargetInfo(orgId, targetProvider, targetId, envId (empty)) : TargetInfo
box "Atlas API"
  participant AtlasAPI #lightblue
end box
AtlasClient ->> AtlasAPI : /api/v1\n/organizations/{orgId}\n/providers/{targetProvider}\n/targets/{targetId}
note right: environment would go in the query string.

TargetService ->> Client : TargetInfo

@enduml
```

### Publish synchronize notification - API Endpoint

API: [POST /admin/usage/sync]

Description: Forces a synchronization of deployments status. 


```plantuml

@startuml
skinparam maxMessageSize 20
box "HTTP Client"
  actor Client #lightblue
end box
Client ->> SynchronizationController : getDeploymentsForSync(batchSize, UsageSyncRequest, organizationId)\n POST /admin/usage/sync
SynchronizationController ->> DeploymentService: performsSyncWithMetricsInBatches(new Date(), batchSize, body.getReportNames(), organizationId)
SynchronizationController ->> DeploymentService: getDeploymentsWithCurrentSpecOnlyInBatchesBetweenDates(from, limitDate, batchSize, deploymentsToExclude, maybeOrganizationId) : List<Deployment>

loop deployments

  alt deployment status is not [APPLIED, APPLYING, FAILED]

    alt isCurrentDeploymentSpecRejected(deployment) 

      DeploymentService ->> SpecService: getSpecs(deployment.getId()) : List<Spec>
      DeploymentService ->> DeploymentService : deployment.setCurrentSpec(..)
      note left: update spec with the \nlatest one based on \nit's creation date.

    end

    DeploymnetService ->> BrokerPublisherWrapper : buildAndQueueSyncMessages(deployment, reportNames)
    BrokerPublisherWrapper ->> QuotasMessageFactory : buildSyncMessage(deployment, reportNames, deplyment.getNodeIds()) : BrokerMessage<SyncMessage>
    BrokerPublisherWrapper ->> BrokerPublisher : publish(message)
    box "quotas.Deployments"
      participant QuotasBroker #FF5733
    end box
    BrokerPublisher ->> QuotasBroker : publish(..) quotas.Deployments
  end

end

SynchronizationController ->> Client : HTTP Accepted


@enduml
```

### Process decoration result - JMS Decorator Broker - decorator.SpecDecorationResult 

Description: Deployer Process messages coming from decorator to complete deployment sending the message the TL or update the deployment if it was rejected.

```plantuml

@startuml
skinparam maxMessageSize 20
box "decorator.SpecDecorationResult"
  participant DecoratorBroker #FF5733
end box
DecoratorBroker ->> DecoratorBrokerSubscriber : processDecorationResult\n(DecorationReplyNotification)
DecoratorBrokerSubscriber ->> DeploymentService : findByIdAndFetchSpecs\n(DecorationMessaggeNotification.\ngetDeploymentId()) : Deployment?

alt Deployment is not empty OR Deployment.specVErsion != DecorationResultNotification.specVErsion

  DecoratorBrokerSubscriber ->> DecoratorBrokerSubscriber : log error spec outdated  

else 

  alt DecorationReplyNotification.status is DecorationStatus.SUCCESSFUL

    DecoratorBrokerSubscriber ->> DeploymentsMessageFactory : buildMessagesForDeploymentAndSpec\n(Deployment, \nDecorationReplyNotification.\nspecVersion, Deployment.nodeIds) \n: List<BrokerMessage<DeploymentMessage>>
    DeploymentsMessageFactory ->> TargetService : getTargetInfo(Deployment) : TargetInfo
    DeploymentsMessageFactory ->> DeploymentsMessageFactory : buildMessagesForDeployment\nSpecAndTarget(Deployment, \nDeployment.getSpec(Deployment.specVersion) \nas spec, TargetInfo, \nDeployment.nodeIds) : List<BrokerMessage<DeploymentMessage>>
    DeploymentsMessageFactory ->> DeploymentsMessageFactory : getDeploymentMessageContent\n(Deployment, \nspec, TargetInfo) \n: DeploymentMessageContent
    DeploymentsMessageFactory ->> DecoratedSpecFactory : \ngetDecoratedSpec(\nDeployment.type, \nDeployment.name, \ndeployment.targetProvider.code, spec)\n: DecoratedSpec 

    alt decoratorIntegrationEnabled

      DeploymentsMessageFactory ->> DecoratorService : getDecoratedSpecFromDecorator(\nDeployment, spec, \nDecorationVisibility.ALL)\n: DecoratedSpecDTO
      DecoratorService ->> DecoratedSpecRequestDTO : new(..)
      DecoratorService ->> DecoratorClient : getDecoratedSpec(\nDecoratedSpecRequestDTO): \nDecoratedSpecDTO
      box "HTTP API"
        participant AMCDecoratorAPI #lightblue
      end box
      DecoratorClient ->> AMCDecoratorAPI : /spec/{version}: DecoratorSpecDTO 
      note right: Retrieves a spec \nalready decorated
      DeploymentsMessageFactory ->> TargetInfo : getNodes() : Set<NodeInfo>

      DeploymentsMessageFactory ->> DeploymentsMessageFactory : availableNodes = Set<NodeInfo> filter by Deployment.nodeIDs

      alt optimizedFlexMessagePublication AND Deployment is in standalone 

        DeploymentsMessageFactory ->> DeploymentsMessageFactory : availableNodes = filter availableNodes which DeploymentState != APPLIED
        
        note right #lightgreen: Feature flag specific for flex to avoid publishing messages to nodes which the deployment is already applied

      end

      loop availableNodes : nodeInfo 

        DeploymentsMessageFactory ->> DeploymentsMessageFactory : buildMessageForNode(Deployment, TargetInfo, nodeInfo, spec, DeploymentMessageContent, TargetInfo.enhancedSecurity)

      end

      DeploymentsMessageFactory ->> DecoratorBrokerSubscriber : List<BrokerMessage\n<DeploymentMessage>> 

    end

    DecoratorBrokerSubscriber ->> BrokerPublisher : publish(\nList<BrokerMessage<DeploymentMessage>>) 
    box "{nodeInfo.location}.Provider.\n{target.provider.code}.\nAgent.{nodeInfo.id}.State"
      participant "TransportLayerBroker" #FF5733
    end box
    BrokerPublisher ->> TransportLayerBroker : publish each deployment message
    note right: One message \nper node is sent \nto the target to \nexecute the deployment
  
  else 

    DecoratorBrokerSubscriber ->> DeploymentNotificationService : updateStatusForARejectedDeploymnet(Deployment, DecorationReplyNotification.reason, DeploymentState.FAILED)

  end

  DecoratorBrokerSubscriber ->> TrackingMessageService : untrack(DecorationReplyNotification.deploymentId, DecorationReplyNotification.deploymentId, DecorationReplyNotification.specVersion)

end

@enduml
```

## Destroy -- Document

Description: This seems to be a queue used from a Target to notify Deployer that the target has been modified/deleted etc.
