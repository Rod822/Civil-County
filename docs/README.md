# Civil-County

Roblox-гра на Luau: симуляція міста з громадянами, поліцією і фракціями.

```bash
rojo build -o "Civil-County.rbxlx"
rojo serve
```

## Лабораторні роботи

**Лаб 1A** — профілі гравців (DataStore), фракції/зарплати, сповіщення, Trie-пошук. → [Звіт](./LAB_WORK_1A_REPORT.md)

**Лаб 2** — 15 патернів проєктування (Factory, Builder, Singleton, Adapter, Decorator, Facade, Proxy, Bridge, Command, Observer, Strategy, State, Template Method, Chain of Responsibility, Abstract Factory). → [Звіт](./DESIGN_PATTERNS_REPORT.md)

**Лаб 3a** — паралельний і послідовний merge sort та лінійний пошук через `ThreadPool` (task.spawn). Паралельна версія швидша на 1.5–1.9× від 1000+ елементів.

**Лаб 3b** — мультиагентна симуляція: 10+ NPC на тротуарах, бійки між цивільними, поліція реагує. GUI (Q), RemoteEvents, Command+Undo. Патерни: Strategy, State, Observer, Command. → [Звіт](./LAB3_REPORT.md)

## Тести

127+ юніт-тестів (BoatTest): `SimulationTests`, `ParallelTests`, `PatternsTests`, `PlayersDataService`, `AutocompleteSearchService`.

## Інші документи

[Архітектура](./ARCHITECTURE_ANALYSIS.md) · [Конкурентний аналіз](./COMPETITIVE_ANALYSIS.md) · [Глосарій](./GLOSSARY.md)
