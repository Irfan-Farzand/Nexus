import 'package:googleapis_auth/auth_io.dart';

class GetServerKey {
  Future<String> getServerKeyToken() async {
    final scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": "task-nest-549f6",
        "private_key_id": "421b1803d823a4e5e73641bd6cfa1b71f5c4f7ec",
        "private_key":
            "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDjzGi5fGhCXWCE\ncGzmxDyReMTKpHpxn9YlkqsfHgeIVrJDeORufbMOTQNXZCpvH1ZbCyC/4Pg79Av2\nD8an39tIc8qSIrc30NXLs0KWG04zU9N0OMPBpmB1CWNqJ2Fmqp7yWZcZ/L7inF7g\nx1wmueXvWYYVfU3sWT1r/o4aeFYgfv/ax6YSr6VZTsyG/Vj7A33SbkVKMYHGsjKQ\nEiGiEVOd32X9vSUndUtETmDHZ3sR6rQrKgDzVokEBAnsSycQyq1mrDDwz5LmAusN\nKRh6ICR20L9GgS4Mx2cD0Y4jnNgdyj6fQpJ9qgGtaGIFy/DIUaPzMT3MyWqANzYP\nvoTh5Y6xAgMBAAECggEAAM6rA+L7aTUkQIKIWH9N0zCOEGKVlNily3AfQZX5oUJD\nkXdq7YrNILSA/nEe629TQNJCu08CI5MccBVnFh1GjUxoyEJ8UmzqyLUGIJ2LEmeN\nY833lMbSp7eG4uy1NBaZKlmB9celRIHeckRJAOQS6K2zBy1wl1eUenWkkonJGD08\n7To2PXZU0KIbNV+npVs6Tm5FTcT1nM07iLy0rjWFAfGtPdvav6Egkf0BI1zKKHlP\nnt3pvEltR1duL96ZobLu/GOu2lZOn7+Z+mMq1g9t/JElFgSzM4o/RP00bqgZ0chh\n1D1MMKOw+vhLCsLlHiQT8qPwVigGFuFOaDWwkt1hUQKBgQD23sF60ZntVrAcG4RV\nfJcMR5C9B/TWxyhdCIyHRw9JMPZB8gKbbYvRA4e13xdWPzJXbZd2tUmRpTV4B4Yj\nKTD7W1cZZg2TNK3hh3hj5hFYCAnz1h/lARSfCwZNQX22LyMwV74hersbqzWb7K4G\nZbM2q4qz1pcYiNuMIzLcOMtZHQKBgQDsORear7eI9++0PJsA7jvwfGd6K0XB96Wu\nUtKtJ91VfuTvxuARjdV6+dody8Qndh6zxx/v9lpZYJuRgAJAIm9Gxbi/6JXrypeh\nM24KvfbgNquG68gmC5T6omRYTwhHoXajp44LrQ8Py1Ioi7EeDkmddWBOJcsiA92B\nI8VGvQ5rpQKBgCnPAd9l/faW9s5bzqaXqhEXUajh3xI8ulY/K2WBoFIZ66qxbMWb\n4NDuEx63AIHHxCPQWJVvEF2NKCgCxjHQOQ5oorCXevcSNdx7D+WDQi6xddYIzm//\nJdnliRSuYbbn9sKqKXYMDgIalcKpa7ODp707ggsA7afnDZ+HGob3S2D1AoGAMdAo\nRhpf3aZLCfrtxNh4E1Joj76oSyrp6UTV4GXTqr/Djzyk6465QeGGOVpK1vd1qfuH\npJaSnt5cb+ZKkzOvu4DeYLmvQ7XJG9k4j1NXyBg/O4hlAIDYvbGY73ZbDJ/j4Mbo\nkVXBI1eAz8QFaY0hwO6LjG8z0sx13VGpvC0J6XECgYEAz3DtpvuV3WKLTisZPR5z\n4MZdFBEqgWN1zSnp9z2BZZ9P7gfeAr1oyFCnfth1OsvhC0jqEaH/n5SmsDPzUkh1\n/VWmLfzYl95TbmUISgzlpSdlbI+iUfqHNM1fw+mFMnt1OndtmFpAcvsNC1g1JiIn\npj5kL36HeTxTA783oooXWeY=\n-----END PRIVATE KEY-----\n",
        "client_email":
            "firebase-adminsdk-fbsvc@task-nest-549f6.iam.gserviceaccount.com",
        "client_id": "103115020092198387166",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40task-nest-549f6.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com",
      }),
      scopes,
    );
    final accessServerKey = client.credentials.accessToken.data;
    return accessServerKey;
  }
}
