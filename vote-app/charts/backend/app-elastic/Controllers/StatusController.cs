using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using BackendApi.Models;
using BackendApi.Services;

namespace BackendApi.Controllers
{
  public class StatusController : ControllerBase
  {
    private readonly ICache cache;
    private static int counterCurrent;
    private static int counterMax;

    static StatusController()
    {
      var rand = new Random();
      counterMax = rand.Next(20, 100);
      counterCurrent = 0;
    }

    public StatusController(ICache cache)
    {
      this.cache = cache;
    }

    [Route("status/healthz")]
    [HttpHead]
    [HttpGet]
    public IActionResult GetHealth()
    {
      if (counterCurrent++ >= counterMax)
      {
        return StatusCode(500, new { message = "unknown error" });
      }
      return Ok(new { message = "backend is healthy" });
    }

    [Route("status/readyz")]
    [HttpHead]
    [HttpGet]
    public IActionResult GetReadiness()
    {
      try
      {
        if (cache.TestConnection())
          return Ok(new { message = "backend is online" });
        else
          return StatusCode(500, new { message = "backend is offline (redis not connected)" });
      }
      catch
      {
        return StatusCode(500, new { message = "backend is offline (exception)" });
      }
    }
  }
}
