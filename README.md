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

```mermaid
sequenceDiagram
  client ->> customer: hola
  customer ->> product: want
  product ->> a: d 
  a ->> b: b
  b ->> c: sd
```

### Deployment - Initial request
```mermaid
sequenceDiagram

Client ->> AMCDeployerAPI : PATCH /deployments<br>/{deploymentId}
AMCDeployerAPI ->> AMCDeployer: update <br>deployment
AMCDeployer ->> AMCAtlasAPI: GET /api/v2<br>/organizations/{orgId}<br>/providers/{targetProviderCode}<br>/targets/{targetId}
note right of AMCDeployer: Apply decorations <br>for secrets and <br>asset references
participant AMCDecoratorAPI 
alt changeSpec?
   rect rgb(174, 237, 245)
     AMCDeployer ->> AMCDecoratorAPI : HTTP /specs<br>/{version}/framework <br>processSpec(DeploymentSpecDTO): <br>ProcessedSpecDTO 
   end
end

alt changeSpec || changeSpecVersion
  AMCDeloyer ->> Deployment : updateReplicas
end

  participant quotas.Deployments 
alt updatedDeployment.specVersion != previousSpecVersion && shouldTriggerPipeline (always true)

rect rgb(237, 76, 119)
  AMCDeployer ->> quotas.Deployments : PipelineRequestMessage <br>quotas.Deployments
end
end

```

### Deployment - Quotas 
```mermaid
sequenceDiagram

QuotasBroker ->> AMCQuotas : quotas.Deployments

participant quotas.DeploymentsReport 

participant quotas.Reports 

alt if operationType.delete

  rect rgb(237, 76, 119)
    AMCQuotas ->> quotas.DeploymentsReport : Deployment.APPROVED 
  end
  note left of AMCQuotas: deletes all stored <br>reports for the <br>deployment and sends <br>directly an approval.

else if no reports to be applied to the deployment 

  rect rgb(237, 76, 119)
    AMCQuotas ->> quotas.DeploymentsReport : Deployment.APPROVED 
  end

else if scripting error processing report 

  rect rgb(237, 76, 119)
    AMCQuotas ->> quotas.DeploymentsReport : Deployment.REJECTED 
  end

else 

  alt if operationType.Sync

    AMCQuotas ->> AMCQuotas : Filter reports <br>by reportsName <br>input.
    note right of AMCQuotas: There's an input <br>param for SYNC <br>which are the set <br>of reports to process.

  end
  
  loop for each report

    AMCQuotas ->> quotas.Reports : send reports <br>to process

  end

end

quotas.Reports ->> AMCQuotas : ReportProcessMessage

alt operationType.SYNC

  AMCQuotas ->> AMCQuotas : report<br>.setStatus(APPROVED)

else 

  alt report has LimitProvider
      participant LimitProviderAPI 

    rect rgb(174, 237, 245)
      AMCQuotas ->> LimitProviderAPI : getLimit
    end

    alt usage within limits of deployment request

      AMCQuotas ->> AMCQuotas : report<br>.setStatus(APPROVED)
    else 

      AMCQuotas ->> AMCQuotas : report<br>.setStatus(REJECTED)
    end

  end
  
end

 participant quotas.Status  

rect rgb(237, 76, 119)
  AMCQuotas ->> quotas.Status : report
end

quotas.Status ->> AMCQuotas : ReportProcessMessage
AMCQuotas ->> AMCQuotas : update ReportProgressResult with ReportProcessMessage and storage

alt if ReportProgressResult.isComplete

  AMCQuotas ->> AMCQuotas : select nodes <br>to use for <br>deployment

  alt if (there are reports without node rejected OR (not enough nodes available AND at least one report by node))

    AMCQuotas ->> AMCQuotas : ReportProcessMessage<br>.setStatus(REJECTED)

  else 

    AMCQuotas ->> AMCQuotas : ReportProgressResult<br>.setStatus(APPROVED)

  end

  AMCQuotas ->> quotas.DeploymentsReport : Deployment(<br>ReportProgressResult<br>.getStatus())
  
else 

  AMCQuotas ->> AMCQuotas : update progress 

end

quotas.DeploymentsReport ->> AMCDeployer : Deployment Status

  participant decorator.SpecDecorationRequest 

  participant transportLayer 
  note left of AMCDeployer: TODO translate <br>parameters to <br>actual meaning.

alt if decoration feature enabled 

  rect rgb(237, 76, 119)
    AMCDeployer ->> decorator.SpecDecorationRequest : SpecDecorationRequest
  end

else 

  loop for each node to deploy 
    AMCDeployer ->> transportLayer : node deployment <br>message <br>(DeploymentMessage) <br>{nodeInfo.location}<br>.Provider.{target.provider.code}<br>.Agent.{nodeInfo.id}<br>.State 
  end

end
```


Questions: 
 * In the diagram above there's an update in the deployment and the specVersion may have change. Examples of changes in a specVersion and how it can affect a deployment?
<!--toc:start-->

- [AMC Deploy - Sequence diagrams](#amc-deploy-sequence-diagrams)
  - [Deployment Update](#deployment-update)
  <!--toc:end-->

## Deployment - Decoration Process

Description: This is the entire process for decorating a specification. A request is sent to queue spec.SpecDecorationRequest in the Decorator Broker TODO complete

```mermaid
sequenceDiagram
  participant decorator.SpecDecorationRequest 
  participant AMCDecorator
  participant AtlasAPI 
  participant decorator.SpecDecorationResult 
  participant decorator.SpecDecorationProviderRequest 
  participant decorator.SpecDecorationProgress 
  participant DecorationProviderAPI 
  participant CSMAPI 
  participant decorator.DeployDestroy 

note right of decorator.SpecDecorationRequest: DECORATION PROCESS - START
decorator.SpecDecorationRequest ->> AMCDecorator: send(PipelineRequestMessage)
alt OperationType is UPSERT

  rect rgb(174, 237, 245)
    AMCDecorator ->> AtlasAPI : fetch decorations configuration 
  end
  note left of AtlasAPI: The decoration <br>configurations rules <br>(see [[ttps://github.com/mulesoft/amc-atlas/blob/master/src/main/resources/decorators/decorators.yml decorators.yml]]) <br>gets applied <br>to the spec <br>and those that <br>match are the <br>decorations that <br>must be applied. <br>There are <br>many decorations <br>by decorator name.

  alt if decoration progress decorations by decorator is empty
    rect rgb(237, 76, 119)
      AMCDecorator ->> decorator.SpecDecorationResult : send(new SpecDecorationResult(.., DecorationResult.SUCCESSFUL, ..))
    end
  else if there are decorations by decorator
    loop for each decoration to do
      rect rgb(237, 76, 119)
        AMCDecorator ->> decorator.SpecDecorationProviderRequest: send(new SpecDecorationProviderRequest(..))
      end
    end
  end

else if OperationType is DELETE
  rect reg(156, 247, 215) 
    AMCDecorator ->> AMCDecorator: fetch SECRET type decorations stored 
  end
  note right of AMCDecorator: This seems <br>not to <br>extensible. This is <br>assuming that only <br>the SECRET type <br>decorations will require <br>deletion. This <br>should probable be <br>made more generic <br>and the decoration <br>should declare <br>if it requires <br>deletion or not.
  alt if there are no decorations
    rect rgb(237, 76, 119)
      AMCDecorator ->> decorator.SpecDecorationProgress : send(new SpecDecorationProgress(.., DecorationStatus.SUCCESSFUL,.. ))
    end
  else if there are decorations
    rect rgb(237, 76, 119)
      AMCDecorator ->> decorator.SpecDecorationProviderRequest : send(new SpecDecorationProviderRequest(.., OperationType.DELETE, ..))  
    end
  end

else if OperationType is SYNC
    rect rgb(237, 76, 119)
      AMCDecorator ->> decorator.SpecDecorationProgress : send(new SpecDecorationProgress(.., DecorationStatus.SUCCESSFUL,.. ))
    end
    note left of AMCDecorator: nothing to do <br>we just send a success <br>result.
end

note right of decorator.SpecDecorationRequest: DECORATION PROCESS - DECORATION PROVIDER REQUEST INVOCATION




```

# bla
```mermaid
%%{
  init: 
    { "sequence": 
      { "wrap": true,
        "diagramMarginY": 1
      } 
    }
}%%
sequenceDiagram
decorator.SpecDecorationProviderRequest ->> AMCDecorator: send(DecorationProcessMessage)

alt OperationType is UPSERT
  alt if all stored decorations are DecorationStatus.SUCCESSUL
    AMCDecorator ->> decorator.SpecDecorationProgress : send(new SpecDecorationProgress(.., DecorationStatus.SUCCESSUL, ..))
    note left of AMCDecorator: A successful <br>message is sent <br>for the decorations <br>of this decoration <br>provider. <br>TODO review why this <br>case could happen.
  else if decorations hasn't being execute by the provider
    
    AMCDecorator ->> DecorationProviderAPI : GET /{endpoint}     

    rect reg(156, 247, 215) 
      note right of DecorationProviderAPI : {endpoint} it's <br>defined in Atlas <br><a href='https://github.com/mulesoft/amc-atlas/blob/60d5c5dd8e0c4ec1c525e2d09af823808a9add4e/src/main/resources/decorators/decorators.yml#L62'>decorator configuration</a>.
    end
    alt if all decorations are successful
      AMCDecorator ->> decorator.SpecDecorationProgress: send(new SpecDecorationProgress(.., DecorationStatus.SUCCESSUL, ..))
    else if there are failed decorations
      AMCDecorator ->> decorator.SpecDecorationProgress: send(new SpecDecorationProgress(.., DecorationStatus.FAILED, ..))
    end
  end
else OperationType is DELETE
  loop for each secret decoration
    AMCDecorator ->> CSMAPI: DELETE /secrets-manager<br>/internal/api/v1<br>/organizations/{orgId}<br>/environments/{envId}<br>/clients/{clientId}<br>/secretsGroup/{secretGroupId}<br>/sharedSecrets/  
    note right of CSMAPI: environtments/{envId} <br>is optional given<br> that the secret <br>may not be related <br>to an env.
  end 
  AMCDecorator ->> decorator.SpecDecorationProgress: send(new SpecDecorationProgress(.., DecorationStatus.SUCCESSUL, ..))
end

note right of decorator.SpecDecorationRequest: DECORATION PROCESS - DECORATION PROCESS PROVIDER RESULTS
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
    note right of AMCDeployer: Deleting secrets <br>after successfully <br>deleted them <br> from CSM
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
decorator.SpecDecorationProviderRequest ->> AMCDecorator: send(DecorationProcessMessage)

alt OperationType is UPSERT
  alt if all stored decorations are DecorationStatus.SUCCESSUL
    AMCDecorator ->> decorator.SpecDecorationProgress : send(new SpecDecorationProgress(.., DecorationStatus.SUCCESSUL, ..))
    note left of AMCDecorator: A successful <br>message is sent <br>for the decorations <br>of this decoration <br>provider. <br>TODO review why this <br>case could happen.
  else if decorations hasn't being execute by the provider
    
    AMCDecorator ->> DecorationProviderAPI : GET /{endpoint}     

    rect reg(156, 247, 215) 
      note right of DecorationProviderAPI : {endpoint} it's <br>defined in Atlas <br>[[https://github.com/mulesoft/amc-atlas/blob/60d5c5dd8e0c4ec1c525e2d09af823808a9add4e/src/main/resources/decorators/decorators.yml#L62 decorator configuration]].
    end
    alt if all decorations are successful
      AMCDecorator ->> decorator.SpecDecorationProgress: send(new SpecDecorationProgress(.., DecorationStatus.SUCCESSUL, ..))
    else if there are failed decorations
      AMCDecorator ->> decorator.SpecDecorationProgress: send(new SpecDecorationProgress(.., DecorationStatus.FAILED, ..))
    end
  end
else OperationType is DELETE
  loop for each secret decoration
    AMCDecorator ->> CSMAPI: DELETE /secrets-manager<br>/internal/api/v1<br>/organizations/{orgId}<br>/environments/{envId}<br>/clients/{clientId}<br>/secretsGroup/{secretGroupId}<br>/sharedSecrets/  
    note right of CSMAPI: environtments/{envId} <br>is optional given<br> that the secret <br>may not be related <br>to an env.
  end 
  AMCDecorator ->> decorator.SpecDecorationProgress: send(new SpecDecorationProgress(.., DecorationStatus.SUCCESSUL, ..))
end

note right of decorator.SpecDecorationRequest: DECORATION PROCESS - DECORATION PROCESS PROVIDER RESULTS
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
    note right of AMCDeployer: Deleting secrets <br>after successfully <br>deleted them <br> from CSM
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

```


## AMC Deployer sequence diagrams

### Deployment Update - API Endpoint

API: [PATCH /deployments/{deploymentId}]
From:

- AMC Deployer - DeploymentServiceTest.concurrencyExceptionOnRepositoryShouldBeCaught

```mermaid
sequenceDiagram

  actor Client 

  rect rgb(174, 237, 245)
    Client ->> DeploymentService : update(deploymentId, DeploymentUpdateRequest)<br> PATCH /deploymenys/{deploymentId
  end
  DeploymentService ->> DeploymentRepository : get(deploymentId) : Deployment
  DeploymentService ->> DeploymentService : update(Deployment, DeploymentUpdateRequest, shouldTriggerPipeline)
  DeploymentService ->> TargetRegistry : getTarget(orgId, targetProviderCode, targetId, envId?) : TargetInfo
  TargetRegistry ->> AtlasClient: getTarget(orgId, wtProviderCode, targetId, envId?) : TargetInfo

  participant AtlasAPI 
  rect rgb(174, 237, 245)
    AtlasClient ->> AtlasAPI : GET /api/v1<br>/organizations/{orgId}<br>/providers/{targetProviderCode}<br>/targets/{targetId} 
  end
  DeploymentService ->> TargetService : checkTargetAvailability<br>(deploymentType, target, targetProviderCode)
  TargetService ->> TypeConfiguration : getConfiguration(deploymentType) : DeploymentTypeConfiguration
  TargetService ->> TargetService : isRequireAvailability && !DeploymentTypeConfiguration.isAvailableForDeployments
  note right of TargetService : in mule cloud checks if there's at least a region available

  alt if changeSpec

    DeploymentService ->> DeploymentService : updateSpec(Deployment, DeploymentUpdateRequest, TargetInfo)
    DeploymentService ->> SpecProcessor : update(Deployment, updateRequest.getSpec(), TargetInfo?) : Spec
    note right of SpecProcessor: creates  a spec and validates the spec from <br>AMC or AMF

    alt if decoratorIntegrationEnabled

      SpecProcessor ->> DecoratorClient : getProcessedSpec(DeploymentSpecDTO)
      DecoratorClient ->> DecoratorClient : performRequest(url, Object:DeploymentSpecDTO):ProcessedSpecDTO
      participant AMCDecorator 

      rect rgb(174, 237, 245)
        DecoratorClient ->> AMCDecorator: HTTP /specs/{version}/framework
      end
      SpecProcessor ->> ConfigurationProcessor : getConfigurationWithoutAssets<br>(DeploymentAssetType.CONFIGURATION, ProcessedSpecDTO.<br>getConfigurationWithoutSecrets())
      note left of ConfigurationProcessor: Deploymnet.setSpec(Spec) - updates deployment spec.

    end

  end

  alt if changeSpec || changeSpecVersion
      DeploymentService ->> DeploymentService : Deployment.updateReplicas()
      DeploymentService ->> DeploymentRepository : save(Deployment)
  end

  alt if updatedDeployment.specVersion != prevVersion && shouldTriggerPipeline (always true)
    DeploymentService ->> TargetService : getReplicationStrategy<br>(Deployment.getType(), Deployment.getTargetProvider().getCode(), TargetInfo): strategy
    DeploymentService ->> BrokerPublisherWrapper : buildAndQueueDeployment<br>ReportMessagesWithStrategy(Deployment, OperationType.UPSERT, strategy)
    note right of BrokerPublisherWrapper: Builds and queues the messages for deployment to the <br>QuotasBroker.
    BrokerPublisherWrapper ->> QuotasMessageFactory : buildPipelineRequestMessage<br>(Deployment, OperationType.Upsert, nodesIds, strategy)
    QuotasMessageFactory ->> QuotasRequestMessage : new(..) : QuotasMessageRequest
    QuotasMessageFactory ->> BrokerMessage : quotas("quotas.Deployments", <br>QuotasMessageRequest, ..) : BrokerMessage<PipelineRequestMessage>
    BrokerPublisherWrapper ->> BrokerPublisher : publish(BrokerMessage<PipelineRequestMessage>)
    participant QuotasBroker 
    BrokerPublisher ->> QuotasBroker : publish(..) quotas.Deployments
  end

```

### Process message back from quotas - JMS Listener

JMS Broker: Quotas ; queue: quotas.DeploymentsReport
Description: Deployer Process messages coming from quotas to move deployment to next phase or update the deployment if it was rejected.

```mermaid

sequenceDiagram

  actor Client 
  participant "BrokerService" as bs

  rect rgb(237, 76, 119)
    Client ->> bs : quotas.DeploymentReport
  end
  bs ->> QuotasBrokerSubscriber : processAsDeployerMessagesBackFromQuotas(<br>TextMessage)
  note right of QuotasBrokerSubscriber: TextMessage gets  transformed to  QuotasReplyNotification
  QuotasBrokerSubscriber ->> DeploymentService : findByIdAndFetchSpecs(QuotasReplyNotification.getDeploymentId())<br>:Deployment

  alt QuotasReplyNotification.getStatus().equals(APPROVED)
    QuotasBrokerSubscriber ->> DeploymentService : updateReplicasForSelectedNodes(Deployment, QuotasReplyNotification.getNodes())
    note left of QuotasBrokerSubscriber: It's not directly QuotasReplyNotification.getNodes() but a curated list

    alt if decoratorFeatureEnabled
      QuotasBrokerSubscriber ->> DecoratorMessageFactory : buildSpecDecorationRequestMessage(Deployment, QuotasReplyNotification.getOperationType()):<br>BrokerMessage<br><PipelineRequestMessage>
      DecoratorMessageFactory ->> PipelineMessageUtils : transformDeploymentReportInformation(Deployment, includeFeatureFlags = true) : DeploymentReportInformation
      
      alt includeFeatureFlags
        
        PipelineMessageUtils ->> TargetService : getTargetInfo(Deployment) : TargetInfo
        PipelineMessageUtils ->> PipelineMessageUtils : targetFeatureFlags = TargetInfo.featureFlags
        
        rect reg(156, 247, 215) 
          note right of PipelineMessageUtils: Review feature flags usage per target when making UMP a platform
        end
      end 

      DecoratorMessageFactory ->> PipelineRequestMessage : new(Deployment.id, DeploymentReportInformation)
      DecoratorMessageFactory ->> QuotasBrokerSubscriber : BrokerMessage<PipelineRequestMessage>
      QuotasBrokerSubscriber ->> BrokerPublisher : publish(BrokerMessage)
      note right of BrokerPublisher: Builds a pipeline request message to start our <br>deployment pipeline.
      participant DecoratorBroker 

      rect rgb(237, 76, 119)
        BrokerPublisher ->> DecoratorBroker : send(BrokerMessage) decorator.SpecDecorationRequest
      end

    else -

      QuotasBrokerSubscriber ->> DeploymentsMessageFactory : buildMessagesForDeploymentAndSpec(Deployment, QuotasReplyNotification.getSpecVersion(), <br>QuotasReplyNotification<br>.getSelectedNodes())
      DeploymentsMessageFactory ->> QuotasBrokerSubscriber : List<BrokerMessage<br><DeploymentMessage>> 

      QuotasBrokerSubscriber ->> BrokerPublisher : publish(<br>List<BrokerMessage<DeploymentMessage>>) 
      participant "TransportLayerBroker" 
      BrokerPublisher ->> TransportLayerBroker : publish each deployment message
      note right of TransportLayerBroker: One message <br>per node is sent <br>to the target to <br>execute the deployment

      rect rgb(237, 76, 119)
        QuotasBrokerSubscriber ->> BrokerPublisher : publish(BrokerMessage)
      end
      note right of BrokerPublisher: Build transport messages for a deployment and each node of its target
    end
  end
```

TODO add link between both diagrams

```mermaid

sequenceDiagram

    Client ->> DeploymentsMessageFactory : buildMessagesFor<br>DeploymentAndSpec<br>(Deployment, specVersion, selectedNodes)
    DeploymentsMessageFactory ->> TargetService : getTargetInfo(Deployment) : TargetInfo
    DeploymentsMessageFactory ->> DeploymentsMessageFactory : buildMessagesForDeployment<br>SpecAndTarget(Deployment, <br>Deployment.getSpec(Deployment.specVersion) <br>as spec, TargetInfo, <br>Deployment.nodeIds) : List<BrokerMessage<DeploymentMessage>>
    DeploymentsMessageFactory ->> DeploymentsMessageFactory : getDeploymentMessageContent<br>(Deployment, <br>spec, TargetInfo) <br>: DeploymentMessageContent
    DeploymentsMessageFactory ->> DecoratedSpecFactory : <br>getDecoratedSpec(<br>Deployment.type, <br>Deployment.name, <br>deployment.targetProvider.code, spec)<br>: DecoratedSpec 

    alt decoratorIntegrationEnabled

      DeploymentsMessageFactory ->> DecoratorService : getDecoratedSpecFromDecorator(<br>Deployment, spec, <br>DecorationVisibility.ALL)<br>: DecoratedSpecDTO
      DecoratorService ->> DecoratedSpecRequestDTO : new(..)
      DecoratorService ->> DecoratorClient : getDecoratedSpec(<br>DecoratedSpecRequestDTO): <br>DecoratedSpecDTO
        participant AMCDecoratorAPI 

      rect rgb(174, 237, 245)
        DecoratorClient ->> AMCDecoratorAPI : /spec/{version}: DecoratorSpecDTO 
      end
      note right of AMCDecoratorAPI: Retrieves a spec <br>already decorated
    end

    DeploymentsMessageFactory ->> TargetInfo : getNodes() : Set<NodeInfo>

    DeploymentsMessageFactory ->> DeploymentsMessageFactory : availableNodes = Set<NodeInfo> filter by Deployment.nodeIDs

    alt optimizedFlexMessagePublication AND Deployment is in standalone 

      DeploymentsMessageFactory ->> DeploymentsMessageFactory : availableNodes = filter availableNodes which DeploymentState != APPLIED
      
      rect reg(156, 247, 215) 
        note right of DeploymentsMessageFactory: Feature flag specific for flex to avoid publishing messages to nodes which the deployment is already applied
      end

    end

    loop availableNodes : nodeInfo 

      DeploymentsMessageFactory ->> DeploymentsMessageFactory : buildMessageForNode<br>(Deployment, TargetInfo, <br>nodeInfo, spec, DeploymentMessageContent, <br>TargetInfo.enhancedSecurity)

    end

    DeploymentsMessageFactory ->> Client : List<BrokerMessage<br><DeploymentMessage>> 



```

### BrokerPublisher - JMS message sender

Description: Builds and queues the messages for deployment. Based on the list of input messages it will introspect each message and send the message to different brokers / queues. All JMS messages are sent through this class.

``` mermaid
sequenceDiagram
  participant Client
  participant AnyBroker 
  Client ->> BrokerPublisher: publish(List<BrokerMessage<T>>)
  loop List<BrokerMessage<T>>
    BrokerPublish ->> BrokerPublisher : processMessage(BrokerMessage<T>)
    note right of BrokerPublisher: uses logic for retry
    BrokerPublish ->> BrokerPublish : send(BrokerMessage<T>)
    BrokerPublish ->> MapOfBrokerToJmsTemplate : get(BrokerMessage.getBroker()) : JmsTemplate
    BrokerPulish ->> JmsTemplate : execute(..)
    note right of JmsTemplate: Creates JMS message andsends it.
    rect rgb(237, 76, 119)
      JmsTemplate ->> AnyBroker : publishMessage(..)
    end
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

```mermaid

sequenceDiagram

actor Client
Client ->> TargetService : getTargetInfo(orgId, targetProvider, targetId) : TargetInfo
TargetService ->> AtlasClient : getTargetInfo(orgId, targetProvider, targetId, envId (empty)) : TargetInfo
  participant AtlasAPI 

  rect rgb(174, 237, 245)
    AtlasClient ->> AtlasAPI : /api/v1<br>/organizations/{orgId}<br>/providers/{targetProvider}<br>/targets/{targetId}
  end
  note right of AtlasAPI: environment would go in the query string.

TargetService ->> Client : TargetInfo


```

### Publish synchronize notification - API Endpoint

API: [POST /admin/usage/sync]

Description: Forces a synchronization of deployments status. 


```mermaid

sequenceDiagram

actor Client 

rect rgb(174, 237, 245)
  Client ->> SynchronizationController : getDeploymentsForSync(batchSize, UsageSyncRequest, organizationId)<br> POST /admin/usage/sync
end
SynchronizationController ->> DeploymentService: performsSyncWithMetricsInBatches(new Date(), batchSize, body.getReportNames(), organizationId)
SynchronizationController ->> DeploymentService: getDeploymentsWithCurrentSpecOnlyInBatchesBetweenDates(from, limitDate, batchSize, deploymentsToExclude, maybeOrganizationId) : List<Deployment>

loop deployments

  alt deployment status is not [APPLIED, APPLYING, FAILED]

    alt isCurrentDeploymentSpecRejected(deployment) 

      DeploymentService ->> SpecService: getSpecs(deployment.getId()) : List<Spec>
      DeploymentService ->> DeploymentService : deployment.setCurrentSpec(..)
      note left of DeploymentService: update spec with the <br>latest one based on <br>it's creation date.

    end

    DeploymnetService ->> BrokerPublisherWrapper : buildAndQueueSyncMessages(deployment, reportNames)
    BrokerPublisherWrapper ->> QuotasMessageFactory : buildSyncMessage(deployment, reportNames, deplyment.getNodeIds()) : BrokerMessage<SyncMessage>
    BrokerPublisherWrapper ->> BrokerPublisher : publish(message)
    participant QuotasBroker 
    rect rgb(237, 76, 119)
      BrokerPublisher ->> QuotasBroker : publish(..) quotas.Deployments
    end
  end

end

SynchronizationController ->> Client : HTTP Accepted



```

### Process decoration result - JMS Decorator Broker - decorator.SpecDecorationResult 

Description: Deployer Process messages coming from decorator to complete deployment sending the message the TL or update the deployment if it was rejected.

```mermaid

sequenceDiagram

  participant DecoratorBroker 

  rect rgb(237, 76, 119)
    DecoratorBroker ->> DecoratorBrokerSubscriber : processDecorationResult<br>(DecorationReplyNotification)
  end
  DecoratorBrokerSubscriber ->> DeploymentService : findByIdAndFetchSpecs(DecorationMessaggeNotification.<br>getDeploymentId()) : Deployment?

  alt Deployment is not empty OR Deployment.specVErsion != DecorationResultNotification.specVErsion

    DecoratorBrokerSubscriber ->> DecoratorBrokerSubscriber : log error spec outdated  

  else 

    alt DecorationReplyNotification.status is DecorationStatus.SUCCESSFUL

      DecoratorBrokerSubscriber ->> DeploymentsMessageFactory : buildMessagesForDeploymentAndSpec<br>(Deployment, <br>DecorationReplyNotification.<br>specVersion, Deployment.nodeIds) <br>: List<BrokerMessage<DeploymentMessage>>
      DeploymentsMessageFactory ->> TargetService : getTargetInfo(Deployment) : TargetInfo
      DeploymentsMessageFactory ->> DeploymentsMessageFactory : buildMessagesForDeployment<br>SpecAndTarget(Deployment, <br>Deployment.getSpec(Deployment.specVersion) <br>as spec, TargetInfo, <br>Deployment.nodeIds) : List<BrokerMessage<DeploymentMessage>>
      DeploymentsMessageFactory ->> DeploymentsMessageFactory : getDeploymentMessageContent<br>(Deployment, <br>spec, TargetInfo) <br>: DeploymentMessageContent
      DeploymentsMessageFactory ->> DecoratedSpecFactory : <br>getDecoratedSpec(<br>Deployment.type, <br>Deployment.name, <br>deployment.targetProvider.code, spec)<br>: DecoratedSpec 

      alt decoratorIntegrationEnabled

        DeploymentsMessageFactory ->> DecoratorService : getDecoratedSpecFromDecorator(<br>Deployment, spec, <br>DecorationVisibility.ALL)<br>: DecoratedSpecDTO
        DecoratorService ->> DecoratedSpecRequestDTO : new(..)
        DecoratorService ->> DecoratorClient : getDecoratedSpec(<br>DecoratedSpecRequestDTO): <br>DecoratedSpecDTO
        participant AMCDecoratorAPI 

        rect rgb(174, 237, 245)
          DecoratorClient ->> AMCDecoratorAPI : /spec/{version}: DecoratorSpecDTO 
        end
        note right of AMCDecoratorAPI: Retrieves a spec <br>already decorated
        DeploymentsMessageFactory ->> TargetInfo : getNodes() : Set<NodeInfo>

        DeploymentsMessageFactory ->> DeploymentsMessageFactory : availableNodes = Set<NodeInfo> filter by Deployment.nodeIDs

        alt optimizedFlexMessagePublication AND Deployment is in standalone 

          DeploymentsMessageFactory ->> DeploymentsMessageFactory : availableNodes = filter availableNodes which DeploymentState != APPLIED
          
          rect reg(156, 247, 215) 
            note right of DeploymentsMessageFactory: Feature flag specific for flex to avoid publishing messages to nodes which the deployment is already applied
          end
        end

        loop availableNodes : nodeInfo 

          DeploymentsMessageFactory ->> DeploymentsMessageFactory : buildMessageForNode(Deployment, TargetInfo, nodeInfo, spec, DeploymentMessageContent, TargetInfo.enhancedSecurity)

        end

        DeploymentsMessageFactory ->> DecoratorBrokerSubscriber : List<BrokerMessage<br><DeploymentMessage>> 

      end

      DecoratorBrokerSubscriber ->> BrokerPublisher : publish(<br>List<BrokerMessage<DeploymentMessage>>) 
        participant "TransportLayerBroker" 

      rect rgb(237, 76, 119)
        BrokerPublisher ->> TransportLayerBroker : publish each deployment message
      end
      note right of TransportLayerBroker: One message <br>per node is sent <br>to the target to <br>execute the deployment
    
    else 

      DecoratorBrokerSubscriber ->> DeploymentNotificationService : updateStatusForARejectedDeploymnet(Deployment, DecorationReplyNotification.reason, DeploymentState.FAILED)

    end

    DecoratorBrokerSubscriber ->> TrackingMessageService : untrack(DecorationReplyNotification.deploymentId, DecorationReplyNotification.deploymentId, DecorationReplyNotification.specVersion)

  end


```

## Destroy -- Document

Description: This seems to be a queue used from a Target to notify Deployer that the target has been modified/deleted etc.
