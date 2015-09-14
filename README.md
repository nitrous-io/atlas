# Atlas

## Development 

### Requirements
  - Docker ( >= 1.7.1 )
  - Docker Compose ( >= 1.4.0 )
  - Redis ( >= 3.0.0 )
  - Postgres

### Installation
  - Docker Compose

  ```
    curl -L https://github.com/docker/compose/releases/download/1.4.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  ```

### Test

#### Running test

  ```
    $ scripts/test
  ```

#### Test files

  1. Lua unit test
    - `spec/lua/common_spec.lua`

  2. Integration test with docker-compose
    - It creates of 5 containers to run integration test
      1. `Proxy` container
        - This is almost same as production proxy server. It has openresty and lua library files.
      2. `Redis` container
        - This is redis server for proxy server and test. We insert hosts/containers data for test
      3. `ServerX` containers
        - These are target containers for preview proxy. There are [http](https://github.com/nitrous-io/atlas/blob/master/servers/http/Dockerfile)/[websocket](https://github.com/nitrous-io/atlas/blob/master/servers/websocket/Dockerfile) server containers now.
      4. `Test` container
        - This is to run test with configured environment. It sends requests to `proxy` container for these links https://github.com/nitrous-io/atlas/blob/master/docker-compose-test.yml#L8-L13. So we can simulate production environment without changing `/etc/hosts` manually for testing.
    - When we run `scripts/test`, it runs https://github.com/nitrous-io/atlas/blob/master/spec/integration/preview_spec.rb in `Test` container. By `links` setting in https://github.com/nitrous-io/atlas/blob/master/docker-compose-test.yml, it will sends requests to `Proxy` containers, and it will proxy requests to `Server` containers.
    ![screenshot](https://cloud.githubusercontent.com/assets/302481/9760166/56c0c326-5725-11e5-99be-bf173578b91c.png)
    - It is still hard to add tests since we need to change many places at the same time.

### Deployment
  - Please look into https://github.com/nitrous-io/proxy_cookbook.
  - If you want to update `/etc/nginx/ngnix.conf` or `/etc/nginx/sites-enabled/proxy.conf`, you need to change cookbook.
    `proxy/nginx/conf/nginx.conf` and `proxy/nginx/sites-available/proxy.conf` is only for testing

## TODO
  - The tests only covers preview proxy. We need to add tests for freighter proxy
  - Other than running test, there is no way to test properly on development environment.
    Only way is to change `/etc/hosts` file to point to staging/production to test.
    We only use `docker-compose.yml` for it.
    We need to find a way to run this on development for proper test.
  - To update docker image, we need to run `docker-compose -t docker-compose-test build <IMAGE_NAME>`.
    We can more commands to `scripts/test`. i.e `scripts/test build test`
