"use strict";
exports.handler = (event, context, callback) => {
  //Get contents of response
  const response = event.Records[0].cf.response;
  const headers = response.headers;

  //Set new headers
  headers["strict-transport-security"] = [
    {
      key: "Strict-Transport-Security",
      value: "max-age=63072000; includeSubdomains; preload",
    },
  ];
  headers["content-security-policy"] = [
    {
      key: "Content-Security-Policy",
      value:
        "default-src https: ; frame-ancestors 'none' ; img-src * 'self' data: https:; script-src * ; style-src * 'unsafe-inline'; object-src 'self' ; font-src *",
    },
  ];
  //headers["x-content-type-options"] = [
  //  { key: "X-Content-Type-Options", value: "nosniff" },
  //];
  headers["x-frame-options"] = [{ key: "X-Frame-Options", value: "DENY" }];
  headers["x-xss-protection"] = [
    { key: "X-XSS-Protection", value: "1; mode=block" },
  ];

  //Return modified response
  callback(null, response);
};
