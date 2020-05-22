using System.Threading.Tasks;
using StackExchange.Redis;
using Newtonsoft.Json;
using Microsoft.Extensions.Configuration;

namespace BackendApi.Services
{
  public class RedisCache : ICache
  {
    private readonly ConnectionMultiplexer connection;

    public RedisCache(IConfiguration config)
    {
      var connectionString = config.GetValue<string>("REDIS");

      var configurationOptions = new ConfigurationOptions();
      configurationOptions.EndPoints.Add(connectionString);
      configurationOptions.ClientName = "BackendConnection";
      configurationOptions.ConnectTimeout = 500;
      configurationOptions.SyncTimeout = 1000;
      configurationOptions.AbortOnConnectFail = false;
      this.connection = ConnectionMultiplexer.Connect(configurationOptions);
    }

    public async Task<T> Get<T>(string key)
    {
      var json = await connection.GetDatabase().StringGetAsync(key);
      if (string.IsNullOrEmpty(json))
      {
        return default(T);
      }
      return JsonConvert.DeserializeObject<T>(json);
    }

    public async Task CreateOrUpdate<T>(string key, T value)
    {
      var json = JsonConvert.SerializeObject(value);
      await connection.GetDatabase().StringSetAsync(key, json);
    }

    public bool TestConnection()
    {
      return connection.GetDatabase().IsConnected("connectionkey", CommandFlags.None);
    }
  }
}