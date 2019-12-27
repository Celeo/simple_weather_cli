import httpclient

const attribution = "\n\nPowered by Dark Sky: https://darksky.net/poweredby"

proc getForecast(key: string, lat: float32, long: float32): string =
  discard

when isMainModule:
  let client = newHttpClient(timeout = 15)
  echo(attribution)
