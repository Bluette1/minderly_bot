
every 1.day do
  rake 'task_space:check_special_days'
end

every 10.hours do
  rake 'task_space:check_latest_news'
end

