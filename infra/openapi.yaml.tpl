swagger: "2.0"
info:
  title: Demo API
  description: API Gateway configuration for demo API
  version: 1.0.0
host: ""
schemes:
  - https
produces:
  - application/json
paths:
  /v1/health:
    get:
      summary: Health check endpoint
      operationId: health
      x-google-backend:
        address: ${cloud_run_url}
        path_translation: APPEND_PATH_TO_ADDRESS
      responses:
        "200":
          description: Service is healthy
          schema:
            type: object
            properties:
              ok:
                type: boolean
  /v1/items:
    post:
      summary: Create a new item
      operationId: createItem
      consumes:
        - application/json
      x-google-backend:
        address: ${cloud_run_url}
        path_translation: APPEND_PATH_TO_ADDRESS
      responses:
        "200":
          description: Item created successfully
          schema:
            type: object
        "400":
          description: Bad request
  /v1/items/{id}:
    get:
      summary: Get an item by ID
      operationId: getItem
      parameters:
        - name: id
          in: path
          required: true
          type: string
      x-google-backend:
        address: ${cloud_run_url}
        path_translation: APPEND_PATH_TO_ADDRESS
      responses:
        "200":
          description: Item found
          schema:
            type: object
        "404":
          description: Item not found
