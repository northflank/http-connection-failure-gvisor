addEventListener("fetch", (event) => {
  event.respondWith(
    handleRequest(event.request).catch(
      (err) => new Response(err.stack, { status: 500 })
    )
  );
});

const sleep = (ms) => new Promise((r) => setInterval(r, ms));

/**
 * Many more examples available at:
 *   https://developers.cloudflare.com/workers/examples
 * @param {Request} request
 * @returns {Promise<Response>}
 */
async function handleRequest(request) {
  const { pathname } = new URL(request.url);

  if (pathname.startsWith("/api")) {
    // Random sleep duration before responding
    const duration = Math.floor(Math.random() * 5000);
    let payload = "";
    // Random payload size
    const numberOfChars = Math.floor(Math.random() * 50000);
    for (i=0; i < numberOfChars; i++) {
      // Random payload content
      payload += String.fromCharCode(Math.floor(Math.random() * 26));
    }
    await sleep(duration);
    return new Response(JSON.stringify({ pathname, duration, payload, numberOfChars }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  if (pathname.startsWith("/status")) {
    const httpStatusCode = Number(pathname.split("/")[2]);

    return Number.isInteger(httpStatusCode)
      ? fetch("https://http.cat/" + httpStatusCode)
      : new Response("That's not a valid HTTP status code.");
  }

  return fetch("https://welcome.developers.workers.dev");
}