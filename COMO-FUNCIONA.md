# Kaizen: como o app funciona

Guia de estudo do projeto, para a apresentação. Explica o que o app faz, como o código é organizado e o caminho dos dados em cada funcionalidade.

---

## 1. A ideia

**Kaizen** é uma palavra japonesa que significa "melhoria contínua". O app ajuda a criar **rotinas** (por exemplo Manhã, Treino ou Foco), que são grupos de **tarefas** repetidas todo dia, toda semana ou todo mês. Você marca o que fez e acompanha sua **sequência**: quantos dias seguidos você completou a rotina.

## 2. Tecnologias

| O quê | Pra quê |
|---|---|
| **Swift + SwiftUI** | Linguagem e construção das telas |
| **SQLite** (biblioteca SQLite.swift) | Banco de dados local, onde ficam rotinas, tarefas e histórico |
| **MVVM** | Organização do código: Model, View e ViewModel |
| **WidgetKit** | Widgets da tela inicial e da tela de bloqueio |
| **UserNotifications** | Lembretes de cada tarefa, aviso do fim do dia e resumo de domingo |
| **App Intents** | Comandos da Siri (em inglês) |
| **HealthKit** | Leitura do app Saúde: passos, água, exercício, sono, mindfulness |
| **LocalAuthentication** | Bloqueio do app com Face ID |
| **Swift Testing** | Testes automáticos (88 testes) |

## 3. Organização das pastas

```
Compartilhado/     código usado pelo app E pelo widget
  Modelos/         as estruturas de dados: Rotina, Tarefa, Categoria, HistoricoDia
  Dados/           os DAOs: cada um conversa com uma tabela do banco
  NotificationManager, DataUtil, Paleta…
KaizenApp/
  Views/           as telas (SwiftUI)
  ViewModels/      a lógica de cada tela
  Services/        backup, Face ID, app Saúde, notificações, widget
  Intents/         Siri
KaizenWidget/      os widgets
KaizenAppTests/    testes automáticos
```

### O padrão MVVM em uma frase

A **View** só desenha a tela e repassa os toques. O **ViewModel** decide o que fazer e prepara os dados. O **DAO** lê e grava no banco. Por exemplo, marcar uma tarefa segue este caminho:

`LinhaTarefa (View)` → `TarefaViewModel.alternarConcluida` → `TarefaDAO.atualizar` → banco → a tela recarrega.

### Por que existe a pasta "Compartilhado"?

O widget é um **programa separado** do app. Para ele ler as mesmas rotinas, o banco fica num **App Group**, uma pasta compartilhada entre os dois. O código que acessa o banco fica em `Compartilhado/` e é compilado nos dois.

## 4. O banco de dados (tabelas)

| Tabela | Guarda |
|---|---|
| `rotinas` | nome, emoji, frequência (Diária/Semanal/Mensal), dias da semana, categoria, se está ativa |
| `tarefas` | nome, nota, horário do lembrete, dias, tipo (marcar/valor/vezes), meta, métrica do Saúde |
| `categorias` | nome e cor |
| `historico_rotina` | por período: total de tarefas e quantas foram feitas (base da sequência) |
| `conclusoes` | quais tarefas foram feitas em cada período (permite corrigir dias passados) |
| `registros_tarefa` | valor anotado em tarefas de valor (ex.: 2,5 L de água) |
| `pausas` | intervalos em que a rotina ficou pausada |
| `pulos` | dias/semanas que a pessoa escolheu pular |

**Como o app identifica um período:** pela data de início, no formato `"yyyy-MM-dd"`. Um dia é o próprio dia, uma semana é o domingo dela e um mês é o dia 1. Isso fica em `DataUtil.inicioPeriodo`. É por isso que tudo que é "do período atual" funciona igual nas três frequências.

**Migrações:** quando uma versão nova adiciona uma coluna, o `DatabaseManager` roda um `ALTER TABLE` ao abrir o app. Se a coluna já existe, o comando falha em silêncio e nada muda. Assim quem já usava o app não perde dados.

## 5. As funcionalidades, uma a uma

### Tela Hoje (`HojeView` + `HojeViewModel`)
Junta as tarefas do dia de **todas** as rotinas numa lista só. Elas são separadas em Manhã, Tarde, Noite e "A qualquer hora", conforme o horário do lembrete. Depois vêm as tarefas da semana e do mês. Rotinas de folga ou puladas não aparecem.

### Tipos de tarefa
- **Marcar:** uma caixinha de feito ou não feito.
- **Valor:** você anota um número, como água em litros, e a tarefa fica feita quando bate a meta. O valor fica em `registros_tarefa`.
- **Vezes:** cada toque soma 1, por exemplo "Academia 3 vezes na semana" numa rotina semanal.

Truque do código: os tipos Valor e Vezes também marcam a tarefa como feita quando batem a meta. Assim sequência, widget e lembretes funcionam igual para todos os tipos, sem código especial.

### Sequência e recorde (`EstatisticasViewModel`)
- **Sequência:** quantos períodos seguidos estão completos, contando de trás para frente.
- **Neutros:** dia de **folga**, rotina **pausada** e dia **pulado** são pulados na contagem. Eles não somam, mas também não quebram a sequência.
- **Período atual:** só conta se já estiver completo. Enquanto o dia não acaba, a sequência vale até ontem.

### Corrigir dias anteriores (`DiasAnterioresView` + `DiaAnteriorView`)
Esqueceu de marcar ontem? Abra a rotina, toque em "Dias anteriores", escolha o dia e marque as tarefas. A tabela `conclusoes` guarda o que foi feito em cada dia, e o histórico do dia é recalculado na hora.

### Pular um dia (`PuloDAO`)
"Pular hoje" deixa o dia neutro, como uma folga. Os lembretes daquele dia também não tocam.

### Lembretes (`NotificationManager`)
- Cada tarefa pode ter seu horário, e tarefas da mesma rotina no mesmo horário chegam numa notificação só.
- **Lembrete inteligente:** quando você completa as tarefas, o lembrete é reagendado sem elas. Se tudo foi feito, ele não toca.
- A notificação tem os botões **"Marcar como feito"** e **"Adiar 1 hora"**.
- **Fim do dia:** às 21h, só toca se ainda faltar algo.
- **Limite do iOS:** cada app pode ter no máximo 64 notificações agendadas. Por isso o app agenda só os próximos dias e renova a cada abertura (`diasDeJanela`).

### Widget (`KaizenWidget`)
Mostra o progresso do dia, e no widget de tarefas dá para marcar sem abrir o app (`AlternarTarefaIntent`). Ele relê o banco a cada 30 minutos e na virada do dia.

### App Saúde (`SaudeService`)
Uma tarefa de valor pode ser ligada a passos, água, exercício, sono ou mindfulness. Ao abrir o app, o valor é lido do Saúde e anotado sozinho. O app só **lê**, nunca escreve. No sono, se o relógio e o iPhone gravaram a mesma noite, os trechos que se sobrepõem são juntados para não contar duas vezes.

### Outras
- **Resumo:** número do dia, gráfico dos últimos 7 dias, sequência e prêmios.
- **"Sua semana":** resumo do domingo. Dias pulados e folgas não contam contra você.
- **Prêmios:** medalhas por sequência (3, 7, 14… seguidas) e por constância (1, 10, 50… completas).
- **Modelos:** rotinas prontas para começar rápido.
- **Backup:** exporta e importa tudo num arquivo JSON.
- **Face ID:** opcional, em Ajustes.
- **Siri:** comandos em inglês, por exemplo "Mark Treino as done in Kaizen".
- **Boas-vindas:** três telas na primeira abertura.

## 6. Testes

Ficam em `KaizenAppTests/`. Eles testam as regras que são fáceis de errar: sequência com folgas e pausas, datas dos lembretes, partes do dia, resumo semanal, backup (exporta e importa e confere se voltou igual), tarefas de valor e de vezes, e leitura do Saúde.

As regras foram escritas como **funções puras**: recebem dados e devolvem um resultado, sem acessar o banco nem a data real. Por isso dá para testar passando datas fixas, como `hoje: "2026-10-20"`.

Para rodar no Xcode: **⌘U**.

## 7. Um bug interessante para contar

No iPhone com o **iOS 27.2 beta**, a aba Resumo fechava o app. O relatório de erro apontava para uma simples comparação de datas (`agora >= validoAte`).

A causa: o Xcode mais novo usa uma versão do operador `>=` de datas que **ainda não existia** naquele iOS beta. O app tentava chamar uma função que não existia e era encerrado.

A solução foi comparar as datas só com `<`, que existe em todas as versões. Por exemplo, `agora < validoAte ? feitas : 0`.

Para achar isso, foi preciso ler o relatório de erro do celular e conferir no binário quais funções o app importava (`dyld_info -imports`).

## 8. Perguntas que o professor pode fazer

- **Onde ficam os dados?** Num banco SQLite local, no App Group, para o widget também ler. Nada vai para servidor.
- **Por que MVVM?** Separa a tela da lógica. A lógica pode ser testada sem abrir a tela, e as Views ficam simples.
- **Como a sequência não quebra numa folga?** Ao contar de trás para frente, períodos de folga, pausa ou pulo são ignorados (`calcularStreak`).
- **Como o app sabe que virou o dia?** As conclusões guardam a data. Ao listar, só vale o que é do período atual (`concluidaNoPeriodoAtual`). Então não é preciso "zerar" nada à meia-noite.
- **E se o usuário apagar o app?** Os dados somem junto, por isso existe o **backup** em JSON.
- **Como foi testado?** Testes automáticos nas regras, mais testes manuais no simulador e no iPhone.
