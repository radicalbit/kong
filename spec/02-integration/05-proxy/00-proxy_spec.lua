local helpers = require "spec.helpers"
local cjson = require "cjson"

describe("Proxy - disabled interface", function()
  local client, client_ssl

  after_each(function()
    if client then client:close() end
    if client_ssl then client_ssl:close() end
    helpers.stop_kong()
  end)

  for _, env in ipairs({
        { proxy = "off", ssl = "off" },
        { proxy = "off", ssl = "on" },
        { proxy = "on",  ssl = "off" },
        { proxy = "on",  ssl = "on" },
      }) do

    it(("proxy=%s, ssl=%s"):format(env.proxy, env.ssl), function()
      helpers.run_migrations()
      assert(helpers.start_kong(env))

      if env.proxy == "off" then
        assert.has.error(function()
            client = helpers.proxy_client(10000)
          end, "connection refused")
      else
        client = helpers.proxy_client(10000)
        local res = assert(client:send {
          method = "GET",
          path = "/"
        })
        assert.equals(404, res.status)
        assert("table", type(cjson.decode((res:read_body()))))
      end

      if env.ssl == "off" then
        assert.has.error(function()
            client_ssl = helpers.proxy_ssl_client(10000)
          end, "connection refused")
      else
        client_ssl = helpers.proxy_ssl_client(10000)
        local res = assert(client_ssl:send {
          method = "GET",
          path = "/"
        })
        assert.equals(404, res.status)
        assert("table", type(cjson.decode((res:read_body()))))
      end

    end)
  end

end)
