using System;

namespace BackendApi.Models
{
  public class Hits
  {
    public Hits()
    {
      Id = 0;
      Count = 0;
    }
    public Hits(int id)
    {
      Id = id;
      Count = 0;
    }
    public int Id { get; set; }
    public int Count { get; set; }
    public DateTime LastUpdated { get; set; }
    public string BackendVersion { get; set; }
  }
}