using System.Net;
using Microsoft.Azure.Functions.Worker.Http;
using Newtonsoft.Json;
using KamanAzureFunctions.DTOs;

namespace KamanAzureFunctions.Helpers;

public static class ResponseHelper
{
    public static async Task<HttpResponseData> SuccessResponse<T>(
        HttpRequestData req,
        T data,
        string message = "Success",
        HttpStatusCode statusCode = HttpStatusCode.OK)
    {
        var response = req.CreateResponse(statusCode);

        var apiResponse = new ApiResponse<T>
        {
            Success = true,
            Message = message,
            Data = data
        };

        await response.WriteAsJsonAsync(apiResponse);
        return response;
    }

    public static async Task<HttpResponseData> ErrorResponse(
        HttpRequestData req,
        string message,
        HttpStatusCode statusCode = HttpStatusCode.BadRequest,
        string? error = null)
    {
        var response = req.CreateResponse(statusCode);

        var apiResponse = new ApiResponse
        {
            Success = false,
            Message = message,
            Error = error ?? message
        };

        await response.WriteAsJsonAsync(apiResponse);
        return response;
    }

    public static Task<HttpResponseData> UnauthorizedResponse(
        HttpRequestData req,
        string message = "Unauthorized")
    {
        return ErrorResponse(req, message, HttpStatusCode.Unauthorized);
    }

    public static Task<HttpResponseData> ForbiddenResponse(
        HttpRequestData req,
        string message = "Forbidden")
    {
        return ErrorResponse(req, message, HttpStatusCode.Forbidden);
    }

    public static Task<HttpResponseData> NotFoundResponse(
        HttpRequestData req,
        string message = "Resource not found")
    {
        return ErrorResponse(req, message, HttpStatusCode.NotFound);
    }

    public static Task<HttpResponseData> ServerErrorResponse(
        HttpRequestData req,
        string message = "Internal server error",
        string? error = null)
    {
        return ErrorResponse(req, message, HttpStatusCode.InternalServerError, error);
    }
}
