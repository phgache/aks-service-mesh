using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using BackendApi.Models;
using BackendApi.Services;
using Microsoft.Extensions.Configuration;
using OpenTracing;

namespace BackendApi.Controllers
{
  [Route("api/[controller]")]
  [ApiController]
  public class HitsController : ControllerBase
  {
    private readonly ICache cache;
    private readonly ITracer tracer;
    private readonly string version;

    public HitsController(IConfiguration config, ICache cache, ITracer tracer)
    {
      this.cache = cache;
      this.tracer = tracer;
      version = config.GetValue<string>("BACKEND_VERSION");
    }

    private static Dictionary<int, Hits> data = new Dictionary<int, Hits>();

    // GET api/hits/5
    [HttpGet("{id}")]
    public async Task<ActionResult<Hits>> Get(int id)
    {
      string spanId = string.Format("GET {0}", id);
      using (IScope scope = tracer.BuildSpan(spanId).StartActive(finishSpanOnDispose: true))
      {
        var key = id.ToString();
        Hits result = null;
        using (IScope getScope = tracer.BuildSpan("GetHits").AsChildOf(scope.Span).StartActive(finishSpanOnDispose: true))
        {
          result = await cache.Get<Hits>(key);
          if (result != null)
          {
            getScope.Span.SetTag("Id", result.Id);
          }
        }

        if (result == null)
        {
          using (IScope createOrUpdateScope = tracer.BuildSpan("InitHits").AsChildOf(scope.Span).StartActive(finishSpanOnDispose: true))
          {
            result = new Hits(id);
            await cache.CreateOrUpdate<Hits>(key, result);
            createOrUpdateScope.Span.SetTag("Id", result.Id);
          }
        }
        result.BackendVersion = version;
        return result;
      }
    }

    // POST api/hits
    [HttpPost]
    public async Task Post([FromBody] Hits hits)
    {
      string spanId = string.Format("POST {0} {1}", hits.Id, hits.Count);
      using (IScope scope = tracer.BuildSpan(spanId).StartActive(finishSpanOnDispose: true))
      {
        var key = hits.Id.ToString();
        var result = await cache.Get<Hits>(key);
        if (result != null)
        {
          scope.Span.SetTag("Id", result.Id);
        }

        if (result == null)
        {
          result = new Hits(hits.Id);

        }
        using (IScope createOrUpdateScope = tracer.BuildSpan("UpdateHits").AsChildOf(scope.Span).StartActive(finishSpanOnDispose: true))
        {
          result.Count++;
          createOrUpdateScope.Span.SetTag("Count", result.Count);
          result.LastUpdated = DateTime.Now;
          await cache.CreateOrUpdate<Hits>(key, result);
        }
      }
    }

    // DELETE api/hits/5
    [HttpDelete("{id}")]
    public async Task Delete(int id)
    {
      string spanId = string.Format("DELETE {0}", id);
      using (IScope scope = tracer.BuildSpan(spanId).StartActive(finishSpanOnDispose: true))
      {
        var key = id.ToString();
        var result = await cache.Get<Hits>(key);

        if (result != null)
        {
          scope.Span.SetTag("Id", result.Id);
          using (IScope createOrUpdateScope = tracer.BuildSpan("ResetHitsCount").AsChildOf(scope.Span).StartActive(finishSpanOnDispose: true))
          {
            result.Count = 0;
            await cache.CreateOrUpdate<Hits>(key, result);
          }
        }
      }
    }
  }
}
