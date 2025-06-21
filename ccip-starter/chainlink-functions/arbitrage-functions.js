const ethpair = args[0]
const arbpair = args[1]

const apiResponse = await Functions.makeHttpRequest({
  url: `https://625b-58-84-61-113.ngrok-free.app/api/analyze?ethPair=${ethpair}&arbPair=${arbpair}`
})

if (apiResponse.error) {
  console.error(apiResponse.error)
  throw Error("Request failed")
}

const { data } = apiResponse;

console.log('API response data:', JSON.stringify(data, null, 2));

// Return Character Name
return Functions.encodeString(data.execute ? 1 : 0);
