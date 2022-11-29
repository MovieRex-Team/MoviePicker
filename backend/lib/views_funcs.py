from core.models import InternalUser

from django.http import JsonResponse
import jwt


def create_response(result: str, **kwargs) -> JsonResponse:
        returner = {'result': result}
        for kw in kwargs:
            returner[kw] = kwargs[kw]
        return JsonResponse(returner)


def verify_token(request, username) -> InternalUser:
    if not request.headers.keys() & {'token', 'authorization', 'authentication'}: return 0
    token = request.headers.get('token', '') or request.headers.get('authorization', '') or request.headers.get('authentication', '')

    try:
        data = jwt.decode(token, key='fight_club', algorithms=['HS256', ])
    except jwt.InvalidSignatureError:
        return 0
    except jwt.ExpiredSignatureError:
        return 0
    
    
    if not data.keys() >= {'sub', 'username'}: return 0
    
    token_id = data['sub']
    token_username = data['username']

    user = InternalUser.objects.filter(id=token_id, username=token_username)
    if not len(user) or not username == user[0].username: return 0

    return user[0]