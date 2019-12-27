import
  httpclient,
  json,
  os,
  uri,
  strformat,
  strutils,
  xmlparser,
  xmltree
import dotenv

const geoBaseUrl = "http://api.geonames.org/search"
const darkSkyBaseUrl = "https://api.darksky.net/forecast/"
const darkSkyQueryParams = @[
  ("exclude", "minutely,hourly")
]
const attribution = "\n\nForecast powered by Dark Sky: https://darksky.net/poweredby"

proc getLatLng(client: HttpClient, geonameUsername: string, search: string): (float, float) =
  let url = &"{geoBaseUrl}?" & encodeQuery(@[("username", geonameUsername), ("q", search)])
  let response = client.get(url)
  let code = response.code()
  if code.is4xx or code.is5xx:
    echo("Got error response code " & $code & " from Geonames API; could not fetch lat+lng information")
    quit(1)
  let data = parseXml(response.body)
  (data.findAll("lat")[0].innerText().parseFloat(), data.findAll("lng")[0].innerText().parseFloat())

proc getForecast(client: HttpClient, key: string, lat: float, lng: float): string =
  let url = &"{darkSkyBaseUrl}{key}/{lat},{lng}/?" & encodeQuery(darkSkyQueryParams)
  let response = client.get(url)
  let code = response.code()
  if code.is4xx or code.is5xx:
    echo("Got error response code " & $code & " from Dark Sky API; could not fetch weather information")
    quit(1)
  let data = parseJson(response.body)
  let
    current = data["currently"]
    tomorrow = data["daily"]["data"][0]
  (
    "==============================\n  Currently\n==============================\n\n" &
    current["summary"].getStr() & " at " & $current["temperature"].getFloat() & " °F\n" &
    $(current["humidity"].getFloat() * 100) & "% humidity with " & $current["windSpeed"].getFloat() & " mph wind\n\n" &
    "==============================\n  Tomorrow\n==============================\n\n" &
    "Summary: " & tomorrow["summary"].getStr() & "\n" &
    "High: " & $tomorrow["temperatureHigh"].getFloat() & " °F, low: " & $tomorrow["temperatureLow"].getFloat() & " °F"
  )

when isMainModule:
  let client = newHttpClient(timeout = 15000)
  if existsFile(".env"):
    initDotEnv().overload()
  let dsKey = getEnv("SWC_KEY")
  if dsKey == "":
    echo("You must supply a 'SWC_KEY' environment variable. You can use a '.env' file.")
    quit(1)
  let geoUser = getEnv("GEONAME_USER")
  if geoUser == "":
    echo("You must supply a 'GEONAME_USER' environment variable. You can use a '.env' file.")
    quit(1)
  if paramCount() < 2:
    echo("You must supply a city name (or similar location lookup) as a arguments")
    quit(1)

  let (lat, lng) = getLatLng(client, geoUser, commandLineParams().join(" "))
  let forecast = getForecast(client, dsKey, lat, lng)

  echo(forecast)
  echo(attribution)
