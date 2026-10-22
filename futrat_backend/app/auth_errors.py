"""Human-readable credential errors without echoing submitted secrets."""
from fastapi import Request
from fastapi.exceptions import RequestValidationError
from fastapi.exception_handlers import request_validation_exception_handler
from fastapi.responses import JSONResponse


async def validation_error(request: Request, exc: RequestValidationError):
    if request.url.path not in {"/auth/register", "/auth/login", "/users/me"}:
        return await request_validation_exception_handler(request, exc)
    errors = []
    for error in exc.errors():
        field = str(error.get("loc", [""])[-1])
        label = {"username": "никнейм", "email": "никнейм", "password": "пароль"}.get(field, "данные")
        if error["type"] == "missing":
            message = f"Введите {label}"
        elif error["type"] == "value_error":
            message = error["msg"].removeprefix("Value error, ")
        else:
            message = f"Проверьте {label}: неверный формат"
        errors.append({"field": field, "message": message})
    return JSONResponse(status_code=422, content={
        "detail": errors[0]["message"] if errors else "Проверьте введённые данные",
        "errors": errors,
    })
