# Архітектура Civil-County

- 4 сервіси на сервері (PlayersDataService, JobService, NotificationService, AutocompleteSearchService) і простий клієнт.
- Дані зберігаються в `Profile` (persistent + session); Trie використовується для пошуку.
- DataStore доступний лише через PlayersDataService.

## Принципи дизайну
- кожен сервіс виконує одну роль.
- дублювання мінімізовано; тільки кілька методів notification схожі.
- код простий, читається.
- нема зайвих полів чи методів.

## Пропозиції
- Винести конфіг Jobs в окремий файл.
- Передавати сервіси як параметри (dependency injection).
- Замість прямих викликів можна впровадити систему подій.