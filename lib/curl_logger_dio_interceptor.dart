import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

class CurlLoggerDioInterceptor extends Interceptor {
  final bool? printOnSuccess;
  final bool convertFormData;
  final void Function(String msg)? logPrint;

  CurlLoggerDioInterceptor({this.logPrint, this.printOnSuccess, this.convertFormData = true});

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    _renderCurlRepresentation(err.requestOptions);

    return handler.next(err); //continue
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    if (printOnSuccess != null && printOnSuccess == true) {
      _renderCurlRepresentation(response.requestOptions);
    }

    return handler.next(response); //continue
  }

  void _renderCurlRepresentation(RequestOptions requestOptions) {
    // add a breakpoint here so all errors can break
    try {
      if (logPrint == null) {
        log(_cURLRepresentation(requestOptions));
      } else {
        logPrint!(_cURLRepresentation(requestOptions));
      }
    } catch (err) {
      log('unable to create a CURL representation of the requestOptions');
    }
  }

  String _cURLRepresentation(RequestOptions options) {
    List<String> components = ['curl -i'];
    if (options.method.toUpperCase() != 'GET') {
      components.add('-X ${options.method}');
    }

    options.headers.forEach((k, v) {
      if (k != 'Cookie') {
        components.add('-H "$k: $v"');
      }
    });

    if (options.data != null) {
      if (options.data is FormData) {
        if (convertFormData) {
          final fieldData = Map.fromEntries(options.data.fields);
          fieldData.forEach((key, value) {
            components.add('--form $key="$value"');
          });
          final fileData = Map.fromEntries(options.data.files);
          fileData.forEach((key, value) {
            // can show file name only
            components.add('--form =@"${(value as MultipartFile).filename}"');
          });
        }
      } else if (options.headers['content-type'] == 'application/x-www-form-urlencoded') {
        options.data.forEach((k, v) {
          components.add('-d "$k=$v"');
        });
      } else {
        final data = json.encode(options.data).replaceAll('"', '\\"');
        components.add('-d "$data"');
      }
    }

    components.add('"${options.uri.toString()}"');

    return components.join(' \\\n\t');
  }
}
