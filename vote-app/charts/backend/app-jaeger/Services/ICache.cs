using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace BackendApi.Services
{
  public interface ICache
  {
    Task<T> Get<T>(string key);
    Task CreateOrUpdate<T>(string key, T value);
    bool TestConnection();
  }
}