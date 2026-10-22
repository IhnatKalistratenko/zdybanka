using Zdybanka.Application.Services;
using Zdybanka.Data.Repositories;
using Zdybanka.Tests.Common;

namespace Zdybanka.Tests.TagTests;

public class TagTest : ZdybankaTest
{
    protected readonly TagService TagService;

    protected TagTest() : base()
    {
        TagService = new TagService(new TagRepository(_context));
    }
}