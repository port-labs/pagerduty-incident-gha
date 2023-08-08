<img align="right" width="100" height="74" src="https://user-images.githubusercontent.com/8277210/183290025-d7b24277-dfb4-4ce1-bece-7fe0ecd5efd4.svg" />

# Create Pager Duty Incident Action

[![Slack](https://img.shields.io/badge/Slack-4A154B?style=for-the-badge&logo=slack&logoColor=white)](https://join.slack.com/t/devex-community/shared_invite/zt-1bmf5621e-GGfuJdMPK2D8UN58qL4E_g)

This GitHub action allows you to quickly create incidents in PagerDuty via Port Actions with ease.

## Inputs
| Name                 | Description                                                                                          | Required | Default            |
|----------------------|------------------------------------------------------------------------------------------------------|----------|--------------------|
| token                | The Pager Duty Token to use to authenticate with the API with permissions to create incidents      | true     | -                  |
| portClientId         | The Port Client ID to use to authenticate with the API                                           | true     | -                  |
| portClientSecret     | The Port Client Secret to use to authenticate with the API                                       | true     | -                  |
| blueprintIdentifier | The blueprint identifier to use to populate the Port relevant entity                              | false    | pagerdutyIncident |
| incidentTitle        | The title of the incident to create                                                                | true     | -                  |
| extraDetails         | Extra details about the incident to create                                                        | false    | -                  |
| service              | The service id to correlate the incident to                                                       | true     | -                  |
| urgency              | The urgency of the incident to create                                                              | false    | high               |
| actorEmail           | The email of the actor to create the incident with                                                | true     | -                  |
| portRunId            | Port run ID to came from triggering the action                                                    | true     | -                  |


## Quickstart - Create a pager duty incident from the service catalog

Follow these steps to get started with the Golang template

1. Create the following GitHub action secrets
* `PAGER_TOKEN` - a token with permission to create incidents [learn more](https://support.pagerduty.com/docs/generating-api-keys#section-generating-a-personal-rest-api-key)
* `PORT_CLIENT_ID` - Port Client ID [learn more](https://docs.getport.io/build-your-software-catalog/sync-data-to-catalog/api/#get-api-token)
* `PORT_CLIENT_SECRET` - Port Client Secret [learn more](https://docs.getport.io/build-your-software-catalog/sync-data-to-catalog/api/#get-api-token) 

2. Install the Ports GitHub app from [here](https://github.com/apps/getport-io/installations/new).
3. Install Port's pager duty integration [learn more][https://github.com/port-labs/Port-Ocean/tree/main/integrations/pagerduty] 
>**Note** This step is not required for this example, but it will create all the blueprint boilerplate for you, and also update the catalog in real time with the new incident created.
4. After you installed the integration, the blueprints `pagerdutyService` and `pagerdutyIncident` will appear, create the following action with the following JSON file on the `pagerdutyService` blueprint:

```json
[
  {
    "identifier": "trigger_incident",
    "title": "Trigger Incident",
    "icon": "pagerduty",
    "userInputs": {
      "properties": {
        "title": {
          "icon": "DefaultProperty",
          "title": "Title",
          "type": "string"
        },
        "extra_details": {
          "title": "Extra Details",
          "type": "string"
        },
        "urgency": {
          "icon": "DefaultProperty",
          "title": "Urgency",
          "type": "string",
          "default": "high",
          "enum": [
            "high",
            "low"
          ],
          "enumColors": {
            "high": "yellow",
            "low": "green"
          }
        },
        "from": {
          "title": "From",
          "icon": "TwoUsers",
          "type": "string",
          "format": "user",
          "default": {
            "jqQuery": ".user.email"
          }
        }
      },
      "required": [
        "title",
        "urgency",
        "from"
      ],
      "order": [
        "title",
        "urgency",
        "from",
        "extra_details"
      ]
    },
    "invocationMethod": {
      "type": "GITHUB",
      "omitPayload": false,
      "omitUserInputs": true,
      "reportWorkflowStatus": true,
      "org": "port-pagerduty-example",
      "repo": "test",
      "workflow": "trigger.yaml"
    },
    "trigger": "DAY-2",
    "description": "Notify users and teams about incidents in the service",
    "requiredApproval": false
  }
]
```
>**Note** Replace the invocatio method with your own repository details.

5. Create a workflow file under .github/workflows/trigger.yaml with the following content:
```yml
on:
  workflow_dispatch:
    inputs:
      port_payload:
        required: true
        description: "Port's payload, including details for who triggered the action and general context (blueprint, run id, etc...)"
        type: string
    secrets: 
      PAGER_TOKEN: 
        required: true
      PORT_CLIENT_ID:
        required: true
      PORT_CLIENT_SECRET:
        required: true
jobs: 
  trigger:
    runs-on: ubuntu-latest
    steps:
      - uses: port-labs/pagerduty-incident-gha@v1
        with:
          portClientId: ${{ secrets.PORT_CLIENT_ID }}
          portClientSecret: ${{ secrets.PORT_CLIENT_SECRET }}
          token: ${{ secrets.PAGER_TOKEN }}
          portRunId: ${{ fromJson(inputs.port_payload).context.runId }}
          incidentTitle: ${{ fromJson(inputs.port_payload).payload.properties.title }}
          extraDetails: ${{ fromJson(inputs.port_payload).payload.properties.extra_details }}
          urgency: ${{ fromJson(inputs.port_payload).payload.properties.urgency }}
          service: ${{ fromJson(inputs.port_payload).context.entity }}
          blueprintIdentifier: 'pagerdutyIncident'
```
6. Trigger the action from Port UI.

Congrats 🎉 You've created your first incident in PagerDuty from Port!