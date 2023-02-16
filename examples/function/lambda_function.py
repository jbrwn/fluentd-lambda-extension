import os
import jsonpickle


def lambda_handler(event, context):
    print('## ENVIRONMENT VARIABLES\r' +
          jsonpickle.encode(dict(**os.environ)))
    print('## EVENT\r' + jsonpickle.encode(event))
    print('## CONTEXT\r' + jsonpickle.encode(context))

    print("Finished test extensions. Well done!")
