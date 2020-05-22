using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using BackendApi.Models;
using BackendApi.Services;
using Microsoft.Extensions.Configuration;
using Elastic.Apm;
using Elastic.Apm.Api;

namespace BackendApi.Controllers
{
  [Route("api/[controller]")]
  [ApiController]
  public class HitsController : ControllerBase
  {
    private readonly ICache cache;
    private readonly string version;

    public HitsController(IConfiguration config, ICache cache)
    {
      this.cache = cache;
      version = config.GetValue<string>("BACKEND_VERSION");
    }

    private static Dictionary<int, Hits> data = new Dictionary<int, Hits>();

    // GET api/hits/5
    [HttpGet("{id}")]
    public async Task<ActionResult<Hits>> Get(int id)
    {
      var current = Elastic.Apm.Agent.Tracer.CurrentTransaction;
      Hits result = null;

      var key = id.ToString();
      await current.CaptureSpan("Get", "Redis", async (span) =>
      {
        span.Labels["key"] = key;
        result = await cache.Get<Hits>(key);
      });

      if (result == null)
      {
        await current.CaptureSpan("CreateOrUpdate", "Redis", async (span) =>
        {
          span.Labels["key"] = key;
          result = new Hits(id);
          await cache.CreateOrUpdate<Hits>(key, result);
        });
      }
      result.BackendVersion = version;
      return result;
    }

    // POST api/hits
    [HttpPost]
    public async Task Post([FromBody] Hits hits)
    {
      var current = Elastic.Apm.Agent.Tracer.CurrentTransaction;
      Hits result = null;
      var key = hits.Id.ToString();
      await current.CaptureSpan("Get", "Redis", async (span) =>
      {
        span.Labels["key"] = key;
        result = await cache.Get<Hits>(key);
      });

      if (result == null)
      {
        result = new Hits(hits.Id);
      }
      await current.CaptureSpan("CreateOrUpdate", "Redis", async (span) =>
      {
        result.Count++;
        span.Labels["key"] = key;
        result.LastUpdated = DateTime.Now;
        await cache.CreateOrUpdate<Hits>(key, result);
      });
    }

    // DELETE api/hits/5
    [HttpDelete("{id}")]
    public async Task Delete(int id)
    {
      var current = Elastic.Apm.Agent.Tracer.CurrentTransaction;
      Hits result = null;
      var key = id.ToString();
      await current.CaptureSpan("Get", "Redis", async (span) =>
      {
        span.Labels["key"] = key;
        result = await cache.Get<Hits>(key);
      });

      if (result != null)
      {
        await current.CaptureSpan("CreateOrUpdate", "Redis", async (span) =>
        {
          result.Count = 0;
          span.Labels["key"] = key;
          await cache.CreateOrUpdate<Hits>(key, result);
        });
      }

    }
  }
}
