using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

namespace Zdybanka.API.Policies;

public class OwnershipHandler : AuthorizationHandler<OwnershipRequirement>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, OwnershipRequirement requirement)
    {
        string? userId = context.User.FindFirstValue(ClaimTypes.NameIdentifier);

        // The authorization resource is the ID of the resource's owner.
        if (Guid.TryParse(userId, out Guid authenticatedUserId) &&
            context.Resource is Guid ownerId &&
            authenticatedUserId == ownerId)
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
    
}
