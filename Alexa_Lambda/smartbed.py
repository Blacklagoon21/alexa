import boto3
import json

client = boto3.client('iot-data', region_name='us-east-1')
prev_target = 0

def lambda_handler(event, context):
    
    access_token = event['payload']['accessToken']
    if event['header']['namespace'] == 'Alexa.ConnectedHome.Discovery':
        return handleDiscovery(context, event)
    elif event['header']['namespace'] == 'Alexa.ConnectedHome.Control':
        return handleControl(context, event)
    else:
        return "error"
        
def handleDiscovery(context, event):
    payload = ''
    header = {
        "namespace": "Alexa.ConnectedHome.Discovery",
        "name": "DiscoverAppliancesResponse",
        "payloadVersion": "2"
        }

    if event['header']['name'] == 'DiscoverAppliancesRequest':
        payload = {
            "discoveredAppliances":[
                {
                    "applianceId":"SamrtBed",
                    "manufacturerName":"Blacklagoon",
                    "modelName":"model 01",
                    "version":"0.1",
                    "friendlyName":"Smart bed",
                    "friendlyDescription":"Smart bed",
                    "isReachable":True,
                    "actions":[
                        "turnOn",
                        "turnOff"
                    ],
                    "additionalApplianceDetails":{
                        "extraDetail1":"turn on the light",
                        "extraDetail2":"turn off the light",
                        "extraDetail3":"that's all",
                        "extraDetail4":"done."
                    }
                }
            ]
        }
        return {"header": header,"payload": payload}

def handleControl(context, event):
    payload = ''
    response = 0
    device_id = event['payload']['appliance']['applianceId']
    message_id = event['header']['messageId']

    if device_id != "SamrtBed":
        return
    
    if event['header']['name'] == 'TurnOnRequest':
        # Change topic, qos and payload
        response = client.publish(topic='raspberry/smartbed/myroom/status',qos=1, payload=json.dumps({"message":"on"}))
        header = {
        "namespace":"Alexa.ConnectedHome.Control",
        "name":"TurnOnConfirmation",
        "payloadVersion":"2",
        "messageId": message_id
        }
        payload = { }
        
    if event['header']['name'] == 'TurnOffRequest':
        # Change topic, qos and payload
        response = client.publish(topic='raspberry/smartbed/myroom/status',qos=1, payload=json.dumps({"message":"off"}))
        header = {
        "namespace":"Alexa.ConnectedHome.Control",
        "name":"TurnOffConfirmation",
        "payloadVersion":"2",
        "messageId": message_id
        }
        payload = { }
        
    if event['header']['name'] == 'SetTargetTemperatureRequest':
        global prev_target
        
        target = event['payload']['targetTemperature']
        response = client.publish(topic='raspberry/smartbed/myroom/Ttarget',qos=1, payload=json.dumps({"message":"%s"%target}))
        
        header = {
        "namespace":"Alexa.ConnectedHome.Control",
        "name":"SetTargetTemperatureConfirmation",
        "payloadVersion":"2",
        "messageId": message_id
        }
        payload = {
            "targetTemperature":{ "value":target },
            "temperatureMode":{   "value":"AUTO" },
            "previousState":{ 
                "targetTemperature":{ "value": prev_target},
                "mode":{ "value":"AUTO" } 
            }
        }
        prev_target = target
    
    return {"header": header,"payload": payload}