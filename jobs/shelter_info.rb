# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
require 'http'
require 'json'

SCHEDULER.every '1s', :first_in => 0 do |job|
  json = HTTP.
    get('http://admin.r019.hinan/shelter.json').
    body.
    to_s
  shelter = JSON.parse(json)

  send_event('shelter_name', text: shelter['name'])

  refugees = shelter['refugees']
  items = [
    { label: '合計世帯人数', value: refugees['total'] },
    { label: '登録避難者数', value: refugees['registered'] },
    { label: '在室避難者数', value: refugees['present'] }
  ]
  send_event('num_of_refugees', items: items)
end
