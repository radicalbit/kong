local helpers = require "spec.helpers"
local cjson = require "cjson"

describe("Admin API - disabled admin interface", function()
  local client, client_ssl

  after_each(function()
    if client then client:close() end
    if client_ssl then client_ssl:close() end
    helpers.stop_kong()
  end)

  for _, env in ipairs({
        { admin = "off", admin_ssl = "off" },
        { admin = "off", admin_ssl = "on" },
        { admin = "on",  admin_ssl = "off" },
        { admin = "on",  admin_ssl = "on" },
      }) do

    it(("admin=%s, admin_ssl=%s"):format(env.admin, env.admin_ssl), function()
      helpers.run_migrations()
      assert(helpers.start_kong(env))

      if env.admin == "off" then
        assert.has.error(function()
            client = helpers.admin_client(10000)
          end, "connection refused")
      else
        client = helpers.admin_client(10000)
        local res = assert(client:send {
          method = "GET",
          path = "/"
        })
        assert.equals(200, res.status)
        assert("table", type(cjson.decode((res:read_body()))))
      end

      if env.admin_ssl == "off" then
        assert.has.error(function()
            client_ssl = helpers.admin_ssl_client(10000)
          end, "connection refused")
      else
        client_ssl = helpers.admin_ssl_client(10000)
        local res = assert(client_ssl:send {
          method = "GET",
          path = "/"
        })
        assert.equals(200, res.status)
        assert("table", type(cjson.decode((res:read_body()))))
      end

    end)
  end

end)
