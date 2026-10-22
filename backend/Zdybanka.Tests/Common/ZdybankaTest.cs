using Zdybanka.Data;

namespace Zdybanka.Tests.Common;

public class ZdybankaTest : IDisposable
{
    protected readonly ZdybankaContext _context;
    
    public ZdybankaTest()
    {
        _context = ZdybankaContextFactory.Create();
    }
    
    public void Dispose()
    {
        ZdybankaContextFactory.Delete(_context);
    }
}