# :first_in sets how long it takes before the job is first run. In this case, it is run immediately

require 'http'
require 'json'

class ShelterService
  # サービス名
  attr_accessor :name
  # 現在の状態
  attr_reader :status

  def initialize(name)
    @name = name
    @status = :stopped
  end

  def update_status!
    begin
      is_failed = `systemctl is-failed #{name}`
      @status =
        case is_failed.chomp
        when 'active'
          :active
        when 'failed'
          :failed
        else
          :stopped
        end
    rescue
      @status = :stopped
    end

    self
  end
end

STATUS_TO_VALUE = {
  active: '動作中',
  failed: '異常終了',
  stopped: '停止中'
}

service = {
  '入力端末用サーバー' => ShelterService.new('refugee-input-server'),
  '無線通信用サーバー' => ShelterService.new('refugee-com-server'),
  '表示器用サーバー' => ShelterService.new('refugee-display-server')
}

def webapp_status
  webapp = { label: 'Web アプリケーション', value: '停止中' }
  begin
    json = HTTP.get('http://hinan/ping.json').body.to_s
    result = JSON.parse(json)
    webapp[:value] = '動作中' if result['pong']
  rescue
  end

  webapp
end

SCHEDULER.every '1s', :first_in => 0 do |job|
  items = [webapp_status] + service.map do |label, s|
    s.update_status!
    { label: label, value: STATUS_TO_VALUE[s.status] }
  end

  send_event('services', items: items)
end
