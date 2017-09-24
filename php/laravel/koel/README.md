# Koel Music Server

## Setup
- Have the workspace container started; change prot to 3307; run `php artisan migrate`
- Change to 3308 for paid data container; re-run `php artisan migrate`
- Put into Consul the following key

## Steps
- Start with demo0.nomad which starts Quote-as-a-Service
- Also run demo1.nomad to have no Koel service but have a separate Data layer started
