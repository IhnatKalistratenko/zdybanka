using NetTopologySuite.Geometries;

namespace Zdybanka.Core.Extensions;

public static class EventExtensions
{
    public static double GetDistanceToPointInMeters(this Event @event, Point point)
    {
        const double EarthRadius = 6371000;

        Point eventCoordinates = @event.Coordinates;

        var dLat = ToRadians(point.Y - eventCoordinates.Y);
        var dLon = ToRadians(point.X - eventCoordinates.X);

        var lat1 = ToRadians(eventCoordinates.Y);
        var lat2 = ToRadians(point.Y);

        var a = Math.Pow(Math.Sin(dLat / 2), 2) +
                Math.Cos(lat1) * Math.Cos(lat2) *
                Math.Pow(Math.Sin(dLon / 2), 2);

        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

        return EarthRadius * c;
    }

    private static double ToRadians(double degrees)
        => degrees * Math.PI / 180;
}