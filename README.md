# HttpJobProcessing ![Elixir CI](https://github.com/ocraciun/http_job_processing/actions/workflows/elixir.yml/badge.svg)



A http job processing service.

A job is a collection of tasks, where each task has a name and a shell command. Tasks may
depend on other tasks and require that those are executed beforehand. The service takes care
of sorting the tasks to create a proper execution order.

## Installation and running
```bash
git clone https://github.com/ocraciun/http_job_processing.git
cd http_job_processing
mix deps.get
mix run --no-halt
```

After the app is started, you can send requests to http://localhost:4001

### /api/execute
This endpoint executes the job

```bash
curl --location --request POST 'localhost:4001/api/execute' \
--header 'Content-Type: application/json' \
--data-raw '{
    "tasks": [{
        "name": "task-1",
        "command": "touch /tmp/file1"
    },
    {
        "name": "task-2",
        "command":"cat /tmp/file1",
        "requires":[
            "task-3"
        ]
    },
    {
        "name": "task-3",
        "command": "echo '\''Hello World!'\'' > /tmp/file1",
        "requires":[
            "task-1"
        ]
    },
    {
        "name": "task-4",
        "command": "rm /tmp/file1",
        "requires":[
            "task-2",
            "task-3"
        ]
    }]
}'
```

### /api/bash
This endpoint returns the bash script representation of the job

```bash
curl --location --request POST 'localhost:4001/api/bash' \
--header 'Content-Type: application/json' \
--data-raw '{
    "tasks": [{
        "name": "task-1",
        "command": "touch /tmp/file1"
    },
    {
        "name": "task-2",
        "command":"cat /tmp/file1",
        "requires":[
            "task-3"
        ]
    },
    {
        "name": "task-3",
        "command": "echo '\''Hello World!'\'' > /tmp/file1",
        "requires":[
            "task-1"
        ]
    },
    {
        "name": "task-4",
        "command": "rm /tmp/file1",
        "requires":[
            "task-2",
            "task-3"
        ]
    }]
}'
```


## Tests
```bash
mix test
```
