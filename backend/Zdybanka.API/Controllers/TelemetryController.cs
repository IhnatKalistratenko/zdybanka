using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Zdybanka.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TelemetryController : ControllerBase
    {
        [HttpGet(template: "health")]
        public IActionResult HealthCheck()
        {
            return Ok(value: new {status = "ok"});
        }
    }
}
