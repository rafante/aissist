# 📋 DOCUMENTO DE VISÃO COMPLETA DO PRODUTO

**Versão:** 1.0
**Data:** 2026-03-05
**Autor:** Bruno Rafante + Maia
**Status:** Visão completa — todas as features, sem limitações

> Este documento descreve o produto em seu estado final 100% completo.
> Não é um MVP. Não é um roadmap. É o destino.

---

## 1. IDENTIDADE DO PRODUTO

### 1.1 Nome
**A definir.** Critérios estabelecidos:
- Palavra que não precisa existir em nenhum idioma
- Boa sonoridade em português e inglês
- Difícil de confundir com outro serviço existente
- Curta, memorável, registrável (domínio + redes sociais)

Candidatos em avaliação:
- Vyre
- Lumie
- Pikra
- Kura
- Novur
- Synura
- Feelu
- Flicka
- Cinara

### 1.2 Conceito Central

> **Uma plataforma de entretenimento audiovisual onde a inteligência artificial pensa por você.**

O usuário não busca. Não filtra. Não precisa saber o que quer.
A plataforma conhece ele, entende o momento dele e entrega o que ele precisa ver.

### 1.3 Diferencial vs Letterboxd

O Letterboxd é um catálogo social genérico. Bonito, funcional, mas **burro**.
Ele não conhece o usuário. Não direciona. Não personaliza. Não guia.

| Aspecto | Letterboxd | Nosso produto |
|---------|-----------|---------------|
| Recomendações | Genéricas, baseadas em popularidade | Personalizadas por IA, baseadas no perfil único do usuário |
| Listas | Criadas manualmente, sem contexto | Pré-geradas por IA com contexto situacional + criadas por usuários |
| Descoberta | O usuário precisa saber o que procura | A plataforma entrega sem o usuário precisar pensar |
| Interação | Estática (avalia, favorita, lista) | Dinâmica (badges, validações, chat, competições) |
| Comunidade | Passiva (segue, vê diários) | Ativa (chat em tempo real, presença online, DMs, compatibilidade) |
| Dados | Depende de TMDB | Banco próprio enriquecido por IA + comunidade + crawler |
| Gamificação | Inexistente | Economia completa de pontos, títulos, rankings, prêmios |
| Monetização | Pro account básico | Ecossistema completo (freemium, ads, marketplace, API) |

### 1.4 Princípio de Design

> **Zero fricção. O usuário não digita se não quiser. Não pensa se não quiser. Tudo é clique, scroll, hover. Minimalista mas cheio de vida. Cada pixel guia o olho pro próximo clique.**

### 1.5 Objetivo Emocional

O usuário abre pra "ver um filminho" e fica **45 minutos navegando**.
Ele não quer sair. Ele sente que tem gente ali. Ele sente que o site é dele.

---

## 2. EXPERIÊNCIA DO USUÁRIO

### 2.1 Onboarding Inteligente

#### Primeiro Acesso
1. Tela de boas-vindas minimalista e cinematográfica
2. Apresentação de 20–30 produções populares e variadas (filmes, séries, documentários, animes)
3. O usuário avalia cada uma: nota de 1–5 estrelas ou "Não vi" ou "Pular"
4. Pode ser swipe (mobile) ou clique (desktop)
5. Nenhum formulário. Nenhuma pergunta textual. Só interação visual

#### Resultado do Onboarding
- IA traça perfil inicial: gêneros preferidos, ritmo narrativo, tom, complexidade, sensibilidades
- Perfil é refinado continuamente com cada interação futura
- Usuário é imediatamente direcionado para a Home personalizada

#### Variações de Onboarding
- **Express:** 10 produções (pra quem tem pressa)
- **Completo:** 30 produções (perfil mais preciso desde o início)
- **Temático:** "Me diz o que você tá sentindo agora" → IA escolhe produções pra avaliar baseadas no mood

### 2.2 Home — A Tela Viva

A home nunca é estática. Ela respira, muda, pulsa.

#### Elementos da Home

**Hero Banner Rotativo:**
- Produção destaque personalizada pro usuário
- Justificativa da IA: "Baseado no seu amor por thrillers psicológicos e no fato de que você avaliou bem filmes do Denis Villeneuve"
- CTA: "Quero ver" / "Não me interessa" (feedback pro perfil)

**Barra Horizontal Infinita (Ticker de Sugestões):**
- Rola continuamente com sugestões
- Hover pausa e expande: poster + sinopse curta + "por que pra você"
- Clique leva pra página da produção
- Pode ter múltiplas barras temáticas

**Blocos Contextuais Situacionais:**
- Cards grandes e clicáveis com frases situacionais:
  - *"Em casa sozinho numa tarde de domingo"*
  - *"Sexta à noite, amigos reunidos, quer suspense"*
  - *"Madrugada insone, quero algo perturbador"*
  - *"Casal em casa, algo leve e bonito"*
  - *"Família reunida, incluindo crianças"*
  - *"Quero chorar e não tenho vergonha"*
  - *"Preciso de algo pra esquecer o dia"*
- Cada bloco abre uma curadoria IA com produções justificadas individualmente
- IA gera novos blocos periodicamente com base em tendências e perfis

**Feed de Atividade em Tempo Real (Ticker Social):**
- Sutil, não invasivo, tipo um stream lateral ou inferior:
  - 🟢 **@marina** acabou de avaliar *Interestelar* ★★★★★
  - 🟢 **@pedro_cinefilo** criou a lista *"Filmes que merecem mais amor"*
  - 🟢 **@julia** adicionou badge 🧠 *Terror psicológico* em *Hereditário*
  - 🟢 **12 pessoas** estão discutindo *Oppenheimer* agora

**Seção "Pra Você":**
- Grid de produções recomendadas pela IA
- Cada card: poster + nota média + badges principais + justificativa curta
- Atualiza em tempo real conforme o usuário interage

**Seção "Trending na Comunidade":**
- Produções mais avaliadas/discutidas nas últimas 24h
- Listas mais seguidas da semana
- Reviews mais curtidas

**Seção "Seus Amigos Estão Assistindo":**
- O que pessoas que você segue avaliaram recentemente
- Filtro rápido: "O que deram 4+ estrelas"

**Contador de Presença:**
- Sutil no header ou rodapé: *"347 pessoas explorando agora"*
- Na página de produção: *"8 pessoas olhando isso agora"*

### 2.3 Página da Produção

Cada filme, série, documentário, anime ou curta tem uma página rica.

#### Informações Base
- Título (original + traduzido)
- Poster + backdrop cinematográfico
- Ano, duração, país de origem
- Gêneros oficiais
- Elenco principal (com fotos)
- Diretor(es), roteirista(s)
- Sinopse oficial + sinopse IA (personalizada pro perfil do usuário)
- Onde assistir (links diretos pros streamings)
- Trailer embutido

#### Avaliação do Usuário
- Nota de 0.5 a 5 estrelas (meio estrela)
- "Já vi" / "Quero ver" / "Não me interessa"
- Data em que assistiu (opcional)
- Review (texto livre, markdown permitido)
- Rewatched? (quantas vezes)

#### Badges da Produção
- Grid visual de todas as badges validadas
- Cada badge com borda colorida indicando nível de validação:
  - ██████ Consenso forte (90%+ validação) — cor vibrante, brilho
  - █████ Bem validada (70%+) — cor sólida
  - ████ Aceita (50%+) — cor normal
  - ███ Disputada (30-50%) — cor pálida
  - ██ Fraca (15-30%) — quase transparente
  - █ Quase morta (<15%) — cinza fantasma
  - Removida automaticamente quando cai abaixo do threshold
- Botão "Adicionar Badge":
  - Autocomplete com badges existentes no catálogo
  - Opção de criar badge nova (texto livre)
  - Badge nova criada por usuário entra como "pendente" até receber primeiras validações
- Cada badge: botão de validar (👍) ou negar (👎)
- Toggle: "Mostrar badges" / "Esconder badges"
- Filtro: "Só badges com X%+ de validação"
- Badges com potencial spoiler (ex: "Plot twist") ficam borradas por padrão

#### Scores e Estatísticas
- Nota média interna (nossos usuários)
- Distribuição de notas (gráfico de barras)
- Notas externas: IMDB, Rotten Tomatoes, Metacritic
- Quantos usuários avaliaram
- Quantos têm na lista "Quero ver"
- Posição em rankings por gênero/ano/país

#### Seção Social
- Reviews dos usuários (ordenáveis: mais recentes, mais curtidas, amigos primeiro)
- Listas que incluem essa produção
- Chat da produção (ver seção 2.7)
- "Quem também gostou disso assistiu:" (recomendações cruzadas)

#### IA na Página
- "Por que você pode gostar:" — justificativa personalizada
- "Produções similares pro seu perfil:" — não genérico, personalizado
- "Essa produção combina com suas listas:" — sugestão de adicionar

### 2.4 Listas

#### Tipos de Listas

**Listas de Usuário:**
- Qualquer usuário pode criar listas públicas ou privadas
- Título, descrição, capa customizável
- Ordenação manual (drag & drop) ou automática (nota, ano, etc.)
- Comentários nos itens da lista (por que aquele filme tá ali)
- Colaborativa: pode convidar outros pra co-editar

**Listas IA (Pré-Geradas):**
- A plataforma gera listas automaticamente baseadas em contextos:
  - *"Filmes que te fazem questionar tudo"*
  - *"Séries pra ver com a mãe"*
  - *"Obras-primas que ninguém conhece"*
  - *"Diretores que mereciam mais reconhecimento"*
  - *"Produções de 2025 que passaram batido"*
- Cada item com justificativa IA personalizada pro perfil do usuário
- Atualizadas periodicamente

**Listas Contextuais:**
- Geradas sob demanda quando o usuário clica num bloco situacional
- Completamente personalizadas pro perfil + momento

**Listas de Ranking:**
- Geradas automaticamente: Top 100 por gênero, década, país, badge
- Baseadas nas notas da comunidade
- Atualizadas em tempo real

#### Interações com Listas
- Like / Salvar / Seguir (notificações quando atualizar)
- Comentar na lista inteira ou em itens específicos
- Compartilhar (link direto, redes sociais)
- "Fiz essa lista!" — marcar produções que já assistiu
- Fork: duplicar a lista e customizar
- Chat da lista (ver seção 2.7)

#### Listas Premium (Monetização futura)
- Criadores verificados podem cobrar por listas exclusivas
- Plataforma fica com porcentagem
- Criador ganha dinheiro + pontos

### 2.5 Reviews

#### Criação de Review
- Editor rico (markdown, formatação básica)
- Pode incluir imagens/GIFs
- Marcar como "Contém spoiler" (fica borrada por padrão)
- Dar nota junto com a review
- Tags da review: "Análise", "Opinião rápida", "Comparação", "Teoria"

#### Interações
- Like / Dislike
- Comentar na review
- Compartilhar
- Reportar
- "Útil" / "Engraçada" / "Bem escrita" (reações específicas)

#### Destaque
- Review da semana (mais curtida)
- Reviews de amigos aparecem primeiro
- IA destaca reviews que complementam a visão do usuário ou desafiam (config)

#### Competições de Review
- Semanais e mensais
- Tema: "Melhor review de terror do mês"
- Votação da comunidade
- Vencedor ganha pontos + badge + destaque no perfil
- Usuários podem gastar pontos pra dar boost na visibilidade da review na competição

### 2.6 Perfil do Usuário

#### Informações Públicas
- Nome de usuário + avatar
- Bio curta
- Top 4 produções favoritas (exibidas com destaque, como poster wall)
- Badges conquistadas (títulos de perfil)
- Nível de pontuação (com barra de progresso pro próximo título)
- Estatísticas: produções vistas, reviews escritas, listas criadas
- Gráfico de gêneros preferidos (radar chart)
- Atividade recente
- Listas públicas
- Reviews destacadas

#### Indicadores Sociais
- Seguidores / Seguindo
- Compatibilidade com quem visita o perfil: *"Você e @marina têm 78% de gosto em comum"*
- Online agora (bolinha verde) / Última vez online
- Badges de perfil exibidas com orgulho

#### Configurações Pessoais
- Visibilidade do perfil (público / amigos / privado)
- Notificações granulares
- Toggle de badges (ver ou esconder por padrão)
- Toggle de anúncios (opt-in pra ganhar pontos)
- Tema visual (dark/light/custom)
- Idioma preferido pras sinopses IA

### 2.7 Sistema de Chat

#### Chat Geral (Lobby)
- Sala aberta pra toda a comunidade
- Tópicos livres rolando
- Canais temáticos: "Recomendações", "Polêmicas", "Memes", "Off-topic"
- Moderação por IA (spam, toxicidade, flood)
- Moderadores da comunidade (usuários com alto ranking)

#### Chat por Produção
- Cada filme/série tem sua sala de chat
- Fica na página da produção (lateral ou inferior, collapsable)
- Sistema de spoiler obrigatório:
  - Mensagem marcada como spoiler fica borrada até clicar
  - IA detecta spoilers não marcados e sugere blur automático
- Threads dentro do chat pra organizar discussões
- Pins: mensagens importantes fixadas (por moderadores ou por votos)

#### Chat por Lista
- Cada lista pública tem espaço de discussão
- Criador da lista é moderador do chat
- Seguidores discutem, sugerem adições, debatem

#### Mensagem Direta (DM)
- Disponível entre amigos (follow mútuo)
- Pode enviar: texto, links de produções, listas, reviews
- Sugestão de DM: "Vocês têm gosto parecido, quer mandar uma mensagem?"
- Bloquear / Reportar

#### Grupos
- Usuários podem criar grupos de discussão
- Temáticos: "Clube do filme de sábado", "Amantes de anime"
- Podem ter eventos agendados: "Assistir juntos no sábado às 20h"

### 2.8 Presença Online e Comunidade Viva

#### Indicadores de Presença
- 🟢 Online agora
- 🟡 Há X minutos
- ⚪ Há X horas
- Offline (sem indicador)

#### Onde Aparecem
- Lista de amigos
- Página de produção: "4 pessoas olhando isso agora"
- Chat: indicador no avatar
- Perfil: status atual
- Home: contador geral

#### Status Customizado
- Usuário pode definir: *"Assistindo Breaking Bad S03E07"*
- Atualização automática se integrado com streaming (futuro)
- *"Procurando algo pra ver"* — IA ou outros usuários podem interagir

#### Compatibilidade
- Algoritmo que calcula similaridade de gosto entre dois usuários
- Baseado em: notas dadas, gêneros, badges, listas salvas
- Exibido no perfil quando alguém visita
- Ranking de "Pessoas com gosto parecido com o seu"
- Sugestões de amizade baseadas em compatibilidade

### 2.9 Notificações Inteligentes

**Princípio: relevância, nunca spam.**

#### Tipos de Notificação

**Sociais:**
- Alguém curtiu sua review / lista / badge
- Alguém te seguiu
- Amigo avaliou uma produção
- Alguém comentou na sua review / lista
- Novo seguidor com alta compatibilidade

**IA Proativa:**
- "Faz 3 dias que você não avalia nada. Vi que saiu X que combina com seu perfil"
- "Sua lista 'Noites insones' recebeu 50 likes essa semana 🔥"
- "3 amigos seus assistiram Duna: Parte 2 hoje. Quer ver o que acharam?"
- "Tem 12 pessoas discutindo o final de Breaking Bad agora"
- "Achamos uma produção que pode ser seu próximo 5 estrelas"

**Competições e Conquistas:**
- "Competição de reviews de terror começa amanhã!"
- "Você desbloqueou o título 🏆 Garimpeiro!"
- "Você entrou no Top 10 da semana!"
- "Sua badge 'Plot twist sutil' foi validada por 100 pessoas!"

**Sistema:**
- Novas features
- Manutenção programada
- Prêmios e eventos especiais

#### Configuração
- Granular: cada tipo pode ser on/off
- Canais: push, email, in-app
- Frequência: imediata, digest diário, digest semanal
- Quiet hours configuráveis

### 2.10 Busca e Descoberta

#### Busca Textual
- Busca por: título, pessoa (ator/diretor), badge, lista, usuário
- Autocomplete inteligente
- Resultados agrupados por tipo
- Filtros avançados: gênero, ano, nota, duração, badges, onde assistir

#### Busca por IA (Conversacional)
- Campo de busca aceita linguagem natural:
  - *"Filmes parecidos com Interestelar mas mais sombrios"*
  - *"Séries curtas pra maratonar num fim de semana"*
  - *"Algo que minha avó de 70 anos ia gostar"*
  - *"Aquele filme com o cara que fica preso num loop temporal"*
- IA retorna resultados curados com justificativa

#### Descoberta Passiva
- Blocos contextuais na home
- Barras de sugestão rolantes
- "Explore por badge": clica em "Terror psicológico" e vê tudo com essa badge
- "Explore por mood": mapa visual de moods que leva a curadorias
- "Dive aleatório": botão que joga uma produção aleatória baseada no perfil

---

## 3. INTELIGÊNCIA ARTIFICIAL

### 3.1 AI Companion

O produto tem uma presença de IA que interage com o usuário de três formas:

#### Modo Passivo
- Sugestões na home, feeds, notificações
- Justificativas nas recomendações
- Sinopses personalizadas
- Blocos contextuais gerados
- O usuário não pede nada; a IA entrega

#### Modo Reativo
- Busca conversacional: usuário pergunta, IA responde
- "Me recomenda algo" — IA faz perguntas de refinamento e entrega curadoria
- Chat com a IA sobre uma produção específica (sem spoiler ou com spoiler, conforme config)
- "Compara esses dois filmes pra mim"
- "Me convence a ver esse filme" / "Me convence a NÃO ver"

#### Modo Ativo
- IA inicia interação:
  - Notificações proativas (ver seção 2.9)
  - Challenges: "Essa semana, tente assistir algo de um gênero que você nunca vê"
  - "Você deu 5 estrelas pra 3 filmes do Nolan. Já viu Memento?"
  - Após uma avaliação: "Legal! Baseado nessa nota, atualizei seu perfil. Quer ver o que mudou nas recomendações?"

#### Implementação Técnica
- Não é um chatbot genérico
- É uma presença sutil e integrada em toda a plataforma
- Pode ou não ter uma "face" ou avatar (a definir)
- Tom: amigável, direto, levemente entusiasta, nunca robótico
- Respeita limites: se o usuário desativa modo ativo, fica só passivo/reativo

### 3.2 Perfil IA do Usuário

Cada usuário tem um perfil de IA invisível que é continuamente refinado:

```
UserAIProfile {
  // Preferências de gênero (peso 0-1)
  genre_weights: { action: 0.3, thriller: 0.9, romance: 0.1, ... }
  
  // Preferências de estilo
  preferred_pace: "slow_burn" | "fast" | "balanced"
  complexity_preference: 0.0 - 1.0
  darkness_tolerance: 0.0 - 1.0
  
  // Sensibilidades (coisas que evita)
  avoids: ["gore", "animal_harm", "sexual_violence", ...]
  
  // Padrões de consumo
  average_rating: 3.7
  rating_distribution: { 1: 5%, 2: 10%, 3: 25%, 4: 40%, 5: 20% }
  watches_per_week: 2.3
  preferred_duration: "90-120min"
  preferred_decades: ["2010s", "2020s", "1990s"]
  preferred_countries: ["US", "KR", "JP"]
  
  // Embedding vetorial do gosto completo
  taste_embedding: [0.23, -0.11, 0.87, ...]  // vetor de alta dimensão
  
  // Contexto temporal
  recent_mood_trend: "darker_than_usual"
  seasonal_patterns: { winter: "cozy_dramas", summer: "action_adventure" }
  
  // Social
  influenced_by: ["@user1", "@user2"]  // pessoas cujas avaliações ele segue padrão
  taste_clusters: ["indie_intellectual", "mainstream_blockbuster"]
}
```

### 3.3 Recomendação Engine

#### Camadas de Recomendação

1. **Collaborative Filtering:** Usuários com perfil similar gostaram de X
2. **Content-Based:** Produções com atributos similares ao que o usuário gosta
3. **Badge-Based:** Badges que o usuário validou/gostou → produções com badges similares
4. **Social:** O que amigos e pessoas com alta compatibilidade avaliaram bem
5. **Contextual:** Hora do dia, dia da semana, humor recente, última avaliação
6. **Serendipity:** 10-15% das recomendações são propositalmente fora da zona de conforto

#### Justificativas
Toda recomendação vem com uma justificativa legível:
- "Porque você amou [filme X] e esse tem o mesmo diretor"
- "87% dos usuários com gosto parecido deram 4+ estrelas"
- "Tem a badge 'Terror psicológico' que você sempre valida"
- "Seus amigos @ana e @carlos amaram esse"

### 3.4 IA no Cadastro de Produções

Quando um usuário quer cadastrar uma produção que não existe no banco:

1. Digita o nome da produção
2. IA busca em fontes externas e preenche automaticamente:
   - Título (original + traduções)
   - Ano, duração, país
   - Gêneros
   - Elenco, direção, roteiro
   - Sinopse
   - Poster (quando disponível)
3. Usuário revisa: confirma, corrige ou completa
4. Produção entra como "pendente de validação"
5. Outros usuários validam os dados
6. Após threshold de validações → produção fica oficial
7. IA gera automaticamente: sinopse alternativa, mood tags, embeddings, badges sugeridas

### 3.5 IA na Moderação

- Detecção de spoilers não marcados em reviews e chats
- Detecção de spam, flood, toxicidade
- Detecção de farm de pontos (padrões de validação suspeitos)
- Detecção de contas fake
- Sugestão de blur automático com opção de override pelo usuário
- Relatórios pra moderadores humanos quando confiança é baixa

### 3.6 Eficiência Técnica da IA

- **Embeddings** pré-computados para produções e perfis de usuário
- **Similarity search** vetorial para recomendações (rápido e barato)
- **LLM** usado apenas para:
  - Justificativas textuais das recomendações
  - Respostas conversacionais (busca por IA, companion ativo)
  - Geração de blocos contextuais
  - Moderação de conteúdo
  - Enriquecimento de cadastro
- **Cache agressivo** de respostas similares
- **Prompts otimizados** e testados para custo mínimo por interação
- **Batch processing** para atualizações de perfil e re-geração de recomendações
- **Modelo hierárquico:** modelo leve pra tasks simples, modelo pesado só quando necessário

---

## 4. SISTEMA DE BADGES

### 4.1 O Que São Badges

Badges são tags visuais que os usuários aplicam a produções para descrever características que vão além dos gêneros tradicionais. Elas capturam nuances subjetivas que enriquecem a descoberta e alimentam a IA.

### 4.2 Categorias de Badges

**Conteúdo Sensível:**
- 🔞 +18
- 🩸 Gore
- 💀 Violência gráfica
- ⚠️ Blasfêmia
- 🔫 Violência armada
- 🚬 Uso de drogas
- 🔥 Nudez
- ⚡ Abuso
- 🕷️ Fobias específicas

**Experiência Emocional:**
- 😭 Vai te destruir
- 😂 Comédia pura
- 😰 Tensão constante
- 🧠 Terror psicológico
- 💔 Angústia existencial
- 🥰 Feel-good
- 😤 Revolta
- 🤔 Reflexivo
- 😱 Jump scares
- 🫠 Desconforto proposital

**Elementos Narrativos:**
- 🔄 Plot twist
- 🐌 Slow burn
- ⚡ Ritmo frenético
- 🧩 Complexo
- 🎭 Final aberto
- 📖 Baseado em fatos reais
- 🔁 Não-linear
- 🕳️ Mindfuck
- 💬 Diálogos brilhantes
- 🤫 Mais silêncio que fala

**Contexto Social:**
- 👨‍👩‍👧 Pra ver em família
- 🍿 Sessão com amigos
- 💑 Date night
- 🌙 Sozinho de madrugada
- ☕ Domingo à tarde
- 🎉 Pra animar
- 🛋️ Background (não precisa prestar 100% atenção)

**Qualidade Percebida:**
- 💎 Obra-prima escondida
- 🏆 Clássico
- 🗑️ Trash bom
- 🎬 Visual impecável
- 🎵 Trilha sonora marcante
- 🌍 Culturalmente importante
- 📉 Overhyped
- 📈 Underhyped

**Badges Criadas pela Comunidade:**
- Qualquer frase descritiva que o usuário quiser
- Exemplos reais que podem surgir:
  - "Protagonista irritante de propósito"
  - "Melhor que o original"
  - "Não é o que o trailer mostra"
  - "Precisa de mais de uma assistida"
  - "Vai te fazer pesquisar depois"

### 4.3 Ciclo de Vida da Badge

```
CRIAÇÃO
    │
    ├→ Usuário seleciona badge existente OU cria nova
    │
    ▼
NASCIMENTO
    │
    ├→ Badge aparece na produção com borda neutra (cinza)
    ├→ Outros usuários são notificados (se seguem a produção)
    │
    ▼
VALIDAÇÃO
    │
    ├→ Usuários votam: 👍 Confirma / 👎 Nega
    ├→ Borda muda de cor/intensidade conforme votos acumulam
    │
    ▼
MATURIDADE
    │
    ├→ Badge com alta validação: cor vibrante, destaque
    ├→ Badge disputada: cor pálida
    ├→ Badge rejeitada: some automaticamente
    │
    ▼
EVOLUÇÃO
    │
    ├→ Badge criada por usuário que aparece em 10+ produções 
    │   com alta validação → vira badge oficial do catálogo
    ├→ Criador original recebe pontos permanentes de criador
```

### 4.4 Visual da Badge

```
Nível de validação → Aparência

95%+  → Borda brilhante, glow sutil, cor saturada
80%+  → Borda sólida, cor viva
60%+  → Borda normal, cor padrão
40%+  → Borda fina, cor pálida
20%+  → Quase transparente
<20%  → Cinza fantasma
<10%  → Removida automaticamente
```

### 4.5 Badges e IA

- Cada badge gera embedding vetorial
- Perfil do usuário inclui: badges que ele mais valida, badges que ele mais ignora
- Recomendação considera badges: "Você gosta de 'Slow burn' + 'Terror psicológico' → veja esse"
- IA sugere badges automáticas para produções recém-cadastradas
- IA detecta badges redundantes e sugere merge

### 4.6 Configurações de Badge do Usuário

- Ver/esconder todas as badges
- Filtrar por nível mínimo de validação
- Esconder badges específicas (ex: não quer ver badge de spoiler)
- Badges com conteúdo spoiler ficam borradas por padrão
- Modo "badge explorer": navegar produções por badge

---

## 5. ECONOMIA DE PONTOS E GAMIFICAÇÃO

### 5.1 Como Ganha Pontos

| Ação | Pontos | Notas |
|------|--------|-------|
| Avaliar uma produção | +1 | Incentiva avaliação constante |
| Review que recebe like | +2 por like | Incentiva reviews de qualidade |
| Lista seguida por alguém | +3 por seguidor | Incentiva curadoria |
| Badge adicionada e validada | +5 por validação | Incentiva badges precisas |
| Badge CRIADA que vira popular | +20 bônus | Incentiva inovação de vocabulário |
| Cadastro de produção aprovado | +10 | Incentiva completude do banco |
| Dados corrigidos/completados aprovados | +5 | Incentiva manutenção do banco |
| Comentário com like no chat | +1 por like | Incentiva participação social |
| Interagir com lista de outro (completar, avaliar itens) | +1 | Incentiva engajamento cruzado |
| Tempo de exposição a anúncios | +variável | Opt-in only, ver seção monetização |
| Login diário consecutivo | +1 (streak: +2 após 7 dias, +3 após 30) | Incentiva hábito |
| Vencer competição semanal | +50 | Incentiva competição |
| Vencer competição mensal | +200 | Prêmio maior |
| Indicar amigo que se cadastra | +15 | Growth orgânico |
| Primeiro do mês a avaliar um lançamento | +5 | Incentiva early adopters |

### 5.2 Como Perde Pontos

| Ação | Pontos | Notas |
|------|--------|-------|
| Badge adicionada e desqualificada | -5 | Penaliza imprecisão |
| Dados cadastrados e rejeitados | -8 | Penaliza informação errada |
| Review reportada e removida | -10 | Penaliza conteúdo ruim |
| Spam em chat (detectado por IA) | -15 | Penaliza spam |
| Badge criada que morre sem validação | -2 | Penaliza badge inútil |
| Conta reportada por comportamento | -20 | Penaliza toxicidade |
| Farm detectado (automação/abuso) | -100 | Penaliza abuso severo |

### 5.3 Títulos Conquistáveis

Desbloqueados por milestones específicos:

| Título | Requisito | Ícone |
|--------|-----------|-------|
| **Garimpeiro** | Avaliou 10+ produções desconhecidas que depois ficaram populares | 🏆 |
| **Diretor de Lista** | Tem lista com 100+ likes | 🎬 |
| **Crítico Afiado** | Reviews com mais upvotes da semana (3x) | 🔥 |
| **Maratonista** | Assistiu 50+ produções em 30 dias | 👁️ |
| **Curador de Ouro** | Sugestões salvas por 500+ pessoas | 🌟 |
| **Enciclopédia Viva** | Preencheu dados de 50+ produções aprovados | 📚 |
| **Sniper** | Nota consistentemente próxima da média geral (100+ avaliações) | 🎯 |
| **Gosto Raro** | Perfil com preferências estatisticamente únicas | 💎 |
| **Arquiteto de Badges** | Criou 5+ badges que viraram oficiais | 🏗️ |
| **Comentarista** | 500+ mensagens úteis (com likes) em chats | 💬 |
| **Embaixador** | Indicou 20+ amigos que ficaram ativos | 🤝 |
| **Veterano** | 1 ano+ de conta ativa com atividade constante | 🎖️ |
| **Pioneiro** | Entre os primeiros 1000 usuários | 🚀 |
| **Eclético** | Avaliou bem produções de 15+ gêneros diferentes | 🌈 |
| **Profundo** | Reviews com média de 300+ palavras e alta aprovação | 📝 |
| **Nocturno** | Maioria das atividades entre 00h e 06h | 🌙 |
| **Influencer** | 1000+ seguidores | ⭐ |
| **Detector de Spoiler** | Reportou 50+ spoilers não marcados confirmados | 🛡️ |

### 5.4 Rankings

**Ranking Geral:**
- Baseado em pontos totais acumulados
- Top 100 exibido publicamente
- Atualizado em tempo real

**Rankings Específicos:**
- Melhor reviewer da semana/mês
- Melhor curador (listas) da semana/mês
- Maior contribuidor pro banco de dados
- Maior validador de badges
- Mais influente (seguidores × engajamento)

**Rankings por Nicho:**
- Top reviewer de horror
- Top curador de anime
- Top garimpeiro de cinema asiático
- etc.

### 5.5 Competições

**Semanais:**
- Tema definido: "Melhor review de [gênero]"
- Duração: segunda a domingo
- Votação da comunidade
- Prêmio: pontos + badge temporária de destaque

**Mensais:**
- Tema mais amplo: "Lista do mês"
- Prêmios maiores: pontos + badge permanente + destaque na home

**Especiais (Eventos):**
- Tied a lançamentos: "Review mais criativa de [filme que acabou de sair]"
- Sazonais: "Maratona de Halloween", "Retrospectiva de fim de ano"
- Prêmios exclusivos que não voltam

**Boost com Pontos:**
- Usuário gasta pontos pra dar boost de visibilidade na competição
- Não garante vitória (voto continua sendo da comunidade)
- Estratégia: gastar pontos no timing certo

### 5.6 Peso de Voto

O voto de cada usuário tem peso proporcional à sua reputação:

```
Peso do voto = base_weight × reputation_multiplier

reputation_multiplier:
  0-99 pontos:     1.0x (novo)
  100-499:         1.2x
  500-999:         1.5x
  1000-4999:       2.0x
  5000-9999:       2.5x
  10000+:          3.0x
  
Penalidades:
  Pontuação negativa acumulada: 0.5x
  Conta com menos de 7 dias: 0.3x
  Flag de comportamento: 0.1x
```

Isso faz o sistema se auto-moderar: trolls perdem influência, contribuidores ganham.

### 5.7 Anti-Abuso

- IA monitora padrões: mesma badge em massa, likes coordenados, timing suspeito
- Pontuação negativa acumulada = flag automático pra review
- Rate limiting: máximo de X badges por hora, Y validações por hora
- Cooldown após penalidades
- Ban temporário e permanente pra reincidentes
- Apelação disponível (review humano)

---

## 6. BANCO DE DADOS E CRAWLER

### 6.1 Visão Geral

O produto terá banco de dados próprio, independente de APIs externas para servir conteúdo. O banco é alimentado por três fontes:

1. **Crawler autônomo** (principal, roda 24/7)
2. **Cadastro por usuários** (com assistência IA)
3. **Enriquecimento por IA** (contínuo)

### 6.2 Schema da Produção

```
Production {
  // Identificação
  id: UUID
  slug: String (URL-friendly)
  
  // Títulos
  title_original: String
  title_translations: { pt_BR: "", en_US: "", es: "", ... }
  
  // Classificação
  type: enum (movie, series, documentary, anime, short, miniseries, special)
  genres: [String]
  
  // Metadados básicos
  year: Int
  release_date: Date
  duration_minutes: Int (filmes) / null (séries)
  seasons: Int (séries) / null
  episodes_total: Int (séries) / null
  country_origin: [String]
  languages: [String]
  status: enum (released, upcoming, in_production, cancelled)
  
  // Pessoas
  cast: [{ person_id, character_name, order }]
  directors: [person_id]
  writers: [person_id]
  producers: [person_id]
  composers: [person_id]
  
  // Conteúdo textual
  synopsis_official: String
  synopsis_ai: { pt_BR: "", en_US: "" }  // gerada por IA, personalizada
  tagline: String
  
  // Mídia
  poster_url: String
  backdrop_url: String
  trailer_urls: [String]
  gallery: [String]
  
  // Badges
  badges: [{
    badge_id: UUID,
    text: String,
    emoji: String,
    validations_positive: Int,
    validations_negative: Int,
    validation_ratio: Float,
    created_by: user_id,
    created_at: DateTime,
    is_official: Boolean
  }]
  
  // Mood e IA
  mood_tags: [String]  // gerados por IA
  pace: enum (very_slow, slow, balanced, fast, frenetic)
  complexity: Float (0-1)
  darkness: Float (0-1)
  emotional_impact: Float (0-1)
  embedding: Vector (alta dimensão)
  
  // Onde assistir
  streaming_availability: [{
    provider: String (netflix, prime, disney, etc),
    url: String,
    type: enum (subscription, rent, buy),
    price: Float (se aplicável),
    country: String,
    last_checked: DateTime
  }]
  
  // Scores
  internal_score: Float  // média dos nossos usuários
  internal_votes: Int
  score_distribution: { 0.5: x, 1: x, ..., 5: x }
  external_scores: {
    imdb: { score: Float, votes: Int },
    rotten_tomatoes: { critics: Int, audience: Int },
    metacritic: { score: Int },
    tmdb: { score: Float }
  }
  
  // Metadados do sistema
  source: enum (crawler, user, ai)
  enriched_by: enum (ai, user, both)
  verified: Boolean
  verification_votes: Int
  created_at: DateTime
  updated_at: DateTime
  last_crawled: DateTime
}
```

```
Person {
  id: UUID
  name: String
  birth_date: Date
  death_date: Date (nullable)
  photo_url: String
  bio: String
  known_for: [production_id]
  roles: [enum (actor, director, writer, producer, composer)]
}
```

```
Badge {
  id: UUID
  text: String
  emoji: String
  category: enum (content_warning, emotional, narrative, social_context, quality, community)
  created_by: user_id
  is_official: Boolean  // true quando validada em 10+ produções
  usage_count: Int  // em quantas produções aparece
  created_at: DateTime
}
```

### 6.3 Crawler Autônomo

#### Arquitetura

```
┌──────────────────────────────────────────────┐
│              CRAWLER ORCHESTRATOR             │
│         (roda 24/7, sem intervenção)         │
│                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────┐ │
│  │ SCHEDULER  │  │  FETCHER   │  │ PARSER │ │
│  │            │  │            │  │        │ │
│  │ Cron jobs  │→ │ HTTP calls │→ │ Clean  │ │
│  │ Priority Q │  │ Rate limit │  │ Norm.  │ │
│  │ On-demand  │  │ Retry      │  │ Dedup  │ │
│  └────────────┘  └────────────┘  └────────┘ │
│                                      │       │
│                               ┌──────▼─────┐ │
│                               │ ENRICHER   │ │
│                               │            │ │
│                               │ IA process │ │
│                               │ Embeddings │ │
│                               │ Mood tags  │ │
│                               │ Auto-badge │ │
│                               └──────┬─────┘ │
│                                      │       │
│                               ┌──────▼─────┐ │
│                               │  STORAGE   │ │
│                               │            │ │
│                               │ DB write   │ │
│                               │ Index      │ │
│                               │ Cache inv. │ │
│                               └────────────┘ │
└──────────────────────────────────────────────┘
```

#### Fontes de Dados

| Fonte | Tipo | Dados | Prioridade |
|-------|------|-------|-----------|
| TMDB API | API oficial | Filmes, séries, pessoas, posters | Alta |
| IMDB | Scraping estruturado | Scores, elenco detalhado, trivia | Alta |
| Wikipedia | API + Scraping | Contexto cultural, prêmios | Média |
| Rotten Tomatoes | Scraping | Scores críticos e audiência | Média |
| JustWatch | API/Scraping | Disponibilidade em streaming | Alta |
| Trakt.tv | API | Tendências, watchlists populares | Média |
| MyAnimeList | API | Dados de anime específicos | Média |
| Metacritic | Scraping | Scores | Baixa |

#### Regras de Operação

- **Nunca depende de ação humana** pra funcionar
- **Rate limiting respeitoso** com cada fonte (respeita robots.txt e ToS)
- **Deduplicação inteligente:** mesmo título em fontes diferentes → merge automático
- **Priorização dinâmica:**
  1. Lançamentos recentes (últimos 30 dias)
  2. Produções buscadas por usuários e não encontradas no banco
  3. Produções populares sem dados completos
  4. Catálogo antigo (preenchimento gradual)
- **Atualização periódica:** dados de streaming mudam → re-crawl semanal
- **On-demand:** usuário busca algo que não existe → crawler busca em tempo real, cadastra e retorna

#### Frequência

| Tipo | Frequência |
|------|-----------|
| Novos lançamentos | Diário |
| Atualizações de streaming | Semanal |
| Scores externos | Semanal |
| Catálogo antigo | Contínuo (batch) |
| On-demand (busca do usuário) | Tempo real |
| Fotos e mídia | Semanal |
| Pessoas (atores/diretores) | Mensal |

### 6.4 Enriquecimento por IA

Para cada produção no banco, a IA gera/atualiza:

- **Sinopse alternativa:** Mais pessoal, menos genérica que a oficial
- **Mood tags:** Classificação emocional/atmosférica
- **Pace/complexity/darkness scores:** Métricas numéricas de estilo
- **Badges sugeridas:** IA sugere badges iniciais baseadas nos dados
- **Embeddings:** Vetor de alta dimensão representando a produção
- **Sinopses personalizadas:** Geradas on-demand por perfil do usuário
- **Comparações:** "Se você gostou de X, vai gostar disso porque..."

### 6.5 Qualidade dos Dados

- **Verificação comunitária:** Usuários validam dados cadastrados
- **Cross-reference:** Dados cruzados entre fontes para consistência
- **Confidence score:** Cada campo tem um score de confiança baseado em:
  - Número de fontes que confirmam
  - Número de usuários que validaram
  - Tempo desde última atualização
- **Flags automáticos:** Dados inconsistentes entre fontes são flaggados pra review

### 6.6 API Própria (Futuro — Monetização)

Com banco robusto, a plataforma se torna fornecedora de dados:

```
API Endpoints (v1):
  GET /api/productions          → Catálogo com filtros
  GET /api/productions/:id      → Detalhes completos
  GET /api/productions/:id/badges → Badges com validação
  GET /api/search               → Busca com IA
  GET /api/recommendations      → Recomendações por perfil
  GET /api/trending             → Tendências
  GET /api/people/:id           → Dados de pessoa
  GET /api/streaming/:country   → Disponibilidade
  
  Rate limiting por plano de API
  Documentação completa
  SDK em Python, JavaScript, Dart
```

---

## 7. MONETIZAÇÃO

### 7.1 Planos de Usuário

#### Free (R$ 0)
- Avaliações ilimitadas
- Criar até 5 listas
- 5 buscas por IA por dia
- Badges: visualizar e validar
- Chat: ler (participar com limite)
- Anúncios padrão
- Perfil público básico

#### Premium (R$ 19,90/mês)
- Tudo do Free +
- Listas ilimitadas
- 50 buscas por IA por dia
- AI Companion modo ativo (notificações proativas)
- Sem anúncios (ou opt-in pra ganhar pontos)
- Chat ilimitado
- Perfil customizável (cores, layout)
- Estatísticas avançadas do perfil
- Export de dados (CSV, PDF)
- Badge exclusiva de supporter
- Prioridade no suporte

#### Pro (R$ 39,90/mês)
- Tudo do Premium +
- Buscas IA ilimitadas
- AI Companion conversacional completo
- Acesso antecipado a features novas
- Criar listas premium (monetizar)
- Analytics avançados das suas listas e reviews
- API pessoal (50 requests/dia)
- Badge exclusiva Pro
- Destaque em rankings
- Convite pra beta de features

#### Anual
- Premium: R$ 199/ano (save 17%)
- Pro: R$ 399/ano (save 17%)

### 7.2 Marketplace de Anúncios Internos

#### Conceito
Usuários e empresas podem criar anúncios dentro da plataforma, direcionados ao público segmentado. Usuários opt-in recebem e ganham pontos.

#### Tipos de Anúncios

**Card no Feed:**
- Aparece entre recomendações na home
- Marcado sutilmente como "Patrocinado"
- Mesmo design que cards normais pra não quebrar a experiência
- Exemplo: Estúdio promovendo filme novo

**Banner em Lista:**
- Entre itens de listas públicas populares
- Relevante ao gênero da lista

**Destaque de Produção:**
- Produção aparece com destaque na home de segmento específico
- "Em destaque: [filme] — patrocinado por [streaming]"

**Promoção de Lista Premium:**
- Criador paga pra promover sua lista premium
- Aparece pra público que teria interesse

#### Segmentação Disponível

O anunciante pode segmentar por:
- Gêneros preferidos do público
- Badges mais consumidas
- Faixa de atividade (casual, médio, heavy user)
- Região/país
- Idade (se fornecida)
- Mood atual (baseado em atividade recente)
- Tipo de plano (Free users = mais receptivos a ads)

#### Modelo de Cobrança
- **CPM (Custo por mil impressões):** Base pra display
- **CPC (Custo por clique):** Pra anúncios interativos
- **Flat fee:** Pra destaques na home (posição premium)
- **Comissão:** Pra listas premium promovidas (% do que vende)

#### Usuário Receptor
- **Opt-in explícito:** "Quero ver anúncios e ganhar pontos"
- Ganha pontos por:
  - Visualização: +1 por anúncio visto
  - Interação: +3 por clique relevante
  - Feedback: +1 por marcar "relevante" ou "irrelevante" (ajuda a IA)
- Limites diários configuráveis (max 10, 20 ou 30 anúncios)
- Pode reportar anúncio irrelevante ou ofensivo
- Nunca vê anúncio de algo que marcou como "Não me interessa"

#### Moderação de Anúncios
- IA review automático antes de publicar
- Verificação de conteúdo impróprio
- Verificação de relevância pro público segmentado
- Review humano pra anúncios acima de certo valor
- Blacklist de categorias por anunciante

### 7.3 Parcerias com Streaming

#### Deep Links Comissionados
- Cada produção mostra onde assistir
- Link direto pro streaming (Netflix, Prime, Disney+, etc.)
- Plataforma recebe comissão por redirecionamento (affiliate)
- Tracking por usuário pra analytics

#### Conteúdo Patrocinado
- Streaming paga pra destacar catálogo na plataforma
- "Novidades na Netflix essa semana" — seção patrocinada
- Listas curadas pelo streaming dentro da plataforma
- Previews exclusivos de lançamentos

#### Dados Agregados (Anonimizados)
- Vender insights agregados pra streamings:
  - "45% dos seus assinantes que assistiram X também querem Y"
  - "Badge mais comum no seu catálogo: Slow Burn"
  - "Demanda não atendida: usuários querem mais [gênero] na sua plataforma"

### 7.4 API Comercial

#### Planos de API

| Plano | Requests/mês | Preço |
|-------|-------------|-------|
| Developer | 1.000 | Free |
| Startup | 50.000 | R$ 99/mês |
| Business | 500.000 | R$ 499/mês |
| Enterprise | Ilimitado | Sob consulta |

#### Dados Disponíveis
- Catálogo completo de produções
- Scores internos e externos
- Badges com validação
- Disponibilidade em streaming por país
- Embeddings pré-computados
- Recomendações via API
- Tendências e analytics

### 7.5 Listas Premium (Marketplace de Conteúdo)

- Criadores verificados (conta Pro) podem criar listas pagas
- Preço definido pelo criador (mínimo R$ 2,99)
- Plataforma fica com 30% (padrão marketplace)
- Criador fica com 70%
- Preview gratuito (primeiros 5 itens)
- Reviews das listas premium (pra quem comprou)
- Ranking de melhores listas premium

### 7.6 Funcionalidades Premium Avulsas (Microtransações)

- **Boost de competição:** R$ 1,99 por boost (ou pontos)
- **Badge customizada de perfil:** R$ 4,99 (ícone exclusivo)
- **Tema visual exclusivo:** R$ 2,99
- **Destaque de perfil por 7 dias:** R$ 9,99
- **Gift card pra amigo:** Qualquer valor, dá Premium temporário

### 7.7 Programa de Afiliados

- Usuário indica amigos → ganha pontos e % do que o amigo gastar nos primeiros 3 meses
- Criadores de conteúdo (YouTube, TikTok) ganham link especial
- Dashboard de afiliado com analytics
- Pagamento mensal via Pix/PayPal

### 7.8 Eventos Especiais Patrocinados

- "Semana do Terror" — patrocinado por [marca]
- "Maratona de Oscar" — patrocinado por [streaming]
- Prêmios especiais da marca (produtos, vouchers)
- Branding sutil nos eventos
- Exclusivo pra marcas que façam sentido no contexto (nada genérico)

---

## 8. ARQUITETURA TÉCNICA (VISÃO)

### 8.1 Stack Sugerida

**Backend:**
- Serverpod (Dart) — já em uso no AIssist
- PostgreSQL — banco relacional principal
- Redis — cache, sessões, real-time
- pgvector ou Pinecone — banco vetorial pra embeddings
- WebSocket — chat em tempo real, presença online, notificações

**Frontend:**
- Flutter Web — pra manter stack Dart unificada
- OU Next.js/React — se performance web for prioridade
- Design system próprio
- PWA (Progressive Web App) pra mobile

**IA:**
- API LLM (Claude/GPT) — pra companion, justificativas, moderação
- Modelo de embeddings (OpenAI/Cohere) — pra vetores
- Modelo leve local — pra tasks de baixo custo (classificação, mood tagging)
- Pipeline de prompts otimizado

**Infraestrutura:**
- Docker/Kubernetes
- CDN pra mídia (posters, backdrops)
- Queue system (RabbitMQ/Redis) — pra crawler e processamento assíncrono
- Monitoring (Grafana, Prometheus)
- CI/CD pipeline

**Crawler:**
- Worker independente rodando 24/7
- Queue de prioridade
- Rate limiter por fonte
- Retry com backoff exponencial
- Logs e dashboards de status

### 8.2 Banco de Dados

```
┌─────────────────────────┐
│      PostgreSQL          │
│                          │
│  users                   │
│  productions             │
│  people                  │
│  badges                  │
│  production_badges       │
│  badge_validations       │
│  ratings                 │
│  reviews                 │
│  lists                   │
│  list_items              │
│  follows                 │
│  friendships             │
│  messages (chat)         │
│  notifications           │
│  user_points             │
│  point_transactions      │
│  competitions            │
│  competition_entries     │
│  ads                     │
│  ad_impressions          │
│  streaming_availability  │
│  crawl_logs              │
│  subscriptions           │
│  payments                │
│  api_keys                │
│  api_usage_logs          │
│                          │
└─────────────┬────────────┘
              │
┌─────────────▼────────────┐
│    Vector DB (pgvector)   │
│                           │
│  production_embeddings    │
│  user_profile_embeddings  │
│  badge_embeddings         │
│  search_index             │
│                           │
└───────────────────────────┘
              │
┌─────────────▼────────────┐
│         Redis             │
│                           │
│  session_cache            │
│  online_presence          │
│  rate_limiting            │
│  real_time_counters       │
│  recommendation_cache     │
│  trending_cache           │
│                           │
└───────────────────────────┘
```

### 8.3 Real-Time

- **WebSocket** pra:
  - Chat (geral, por produção, por lista, DMs)
  - Presença online (quem tá on, quem saiu)
  - Notificações push in-app
  - Feed de atividade em tempo real
  - Contadores ("X pessoas olhando isso")
  - Atualizações de score em tempo real

### 8.4 Segurança

- JWT + refresh tokens
- Rate limiting por rota e por usuário
- Sanitização de input (XSS, injection)
- HTTPS everywhere
- Dados sensíveis encriptados at rest
- LGPD compliance (dados de brasileiros)
- GDPR compliance (se expandir pra Europa)
- Export e delete de dados do usuário
- 2FA opcional
- OAuth (Google, Apple, GitHub)

---

## 9. DESIGN E IDENTIDADE VISUAL

### 9.1 Princípios

- **Cinematográfico:** Posters grandes, backdrops, atmosfera de cinema
- **Minimalista mas vivo:** Pouco texto, muito visual, animações sutis
- **Dark mode first:** A maioria usa à noite; light mode disponível
- **Responsivo:** Desktop, tablet, mobile — mesma experiência
- **Acessível:** Contraste adequado, screen reader support, fontes legíveis

### 9.2 Elementos Visuais

- Gradients sutis (azul escuro → roxo → preto)
- Glow effects nos elementos interativos
- Transições suaves entre páginas
- Parallax sutil nos backdrops
- Cards com hover que expandem suavemente
- Posters com bordas arredondadas e sombra
- Avatares redondos com borda de cor do nível
- Badges com animação sutil de pulso quando altamente validadas

### 9.3 Tipografia
- Sans-serif moderna e limpa
- Hierarquia clara: título > subtítulo > corpo > metadata
- Tamanhos generosos pra legibilidade

### 9.4 Animações
- Scroll suave infinito
- Fade-in de conteúdo ao rolar
- Micro-interações: like/dislike, badge validation, rating
- Loading states elegantes (skeletons, não spinners)
- Transição de página fluida

---

## 10. ROADMAP DE FEATURES (REFERÊNCIA)

> Este não é um cronograma. É uma lista de tudo que existe no produto final.
> A priorização pra MVP e fases será feita em sessão separada.

### Tier 1 — Core
- [ ] Cadastro/login (email + OAuth)
- [ ] Perfil do usuário
- [ ] Catálogo de produções
- [ ] Avaliação (nota + review)
- [ ] Busca textual
- [ ] Listas básicas
- [ ] Home personalizada

### Tier 2 — IA
- [ ] Onboarding inteligente (rating pra traçar perfil)
- [ ] Recomendações personalizadas
- [ ] Busca conversacional (linguagem natural)
- [ ] Sinopses IA personalizadas
- [ ] Justificativas nas recomendações
- [ ] Blocos contextuais situacionais
- [ ] AI Companion modo passivo

### Tier 3 — Social
- [ ] Seguir/amigos
- [ ] Feed de atividade
- [ ] Presença online
- [ ] Compatibilidade entre usuários
- [ ] Notificações inteligentes
- [ ] DMs

### Tier 4 — Badges
- [ ] Sistema de badges completo
- [ ] Validação comunitária com visual progressivo
- [ ] Criação de badges pelo usuário
- [ ] Badges oficiais (auto-promoção)
- [ ] Badges como filtro de busca e recomendação

### Tier 5 — Gamificação
- [ ] Economia de pontos (ganhar/perder)
- [ ] Títulos conquistáveis
- [ ] Rankings (geral + específicos)
- [ ] Competições semanais/mensais
- [ ] Boost com pontos
- [ ] Anti-abuso automático

### Tier 6 — Chat
- [ ] Chat geral (lobby)
- [ ] Chat por produção
- [ ] Chat por lista
- [ ] DMs
- [ ] Grupos
- [ ] Sistema de spoiler
- [ ] Moderação IA

### Tier 7 — Dados
- [ ] Crawler autônomo 24/7
- [ ] Cadastro assistido por IA
- [ ] Validação comunitária de dados
- [ ] Enriquecimento IA contínuo
- [ ] Banco próprio independente

### Tier 8 — Monetização
- [ ] Planos Free/Premium/Pro
- [ ] Gateway de pagamento (Stripe/PagSeguro)
- [ ] Marketplace de anúncios
- [ ] Parcerias com streaming (affiliate)
- [ ] API comercial
- [ ] Listas premium (marketplace de conteúdo)
- [ ] Microtransações
- [ ] Programa de afiliados

### Tier 9 — AI Avançada
- [ ] AI Companion modo reativo (conversacional)
- [ ] AI Companion modo ativo (proativo)
- [ ] Moderação IA completa
- [ ] Geração automática de listas contextuais
- [ ] Detecção de spoilers
- [ ] Perfil IA vetorial completo

### Tier 10 — Polish
- [ ] Design system finalizado
- [ ] Animações e transições
- [ ] PWA / App mobile
- [ ] Internacionalização (PT, EN, ES)
- [ ] Acessibilidade completa
- [ ] Performance optimization
- [ ] SEO

---

## 11. MÉTRICAS DE SUCESSO

### Produto
- DAU/MAU ratio > 40% (engagement)
- Tempo médio de sessão > 8 minutos
- Avaliações por usuário por mês > 10
- Retenção D7 > 50%
- Retenção D30 > 30%

### Comunidade
- Badges validadas por dia > X
- Listas criadas por semana > X
- Reviews por dia > X
- Mensagens de chat por dia > X
- % de usuários com ao menos 1 amigo > 60%

### Monetização
- Conversão Free → Premium > 5%
- Conversão Premium → Pro > 15%
- Churn mensal < 5%
- Revenue per user (ARPU)
- LTV/CAC ratio > 3

### Dados
- Cobertura do catálogo: >95% de produções com score >6 no IMDB
- Tempo médio pra produção nova entrar no banco: <24h
- % de produções com badges: >70%
- Freshness dos dados de streaming: <7 dias

---

## 12. CONSIDERAÇÕES FINAIS

Este documento representa a **visão completa** do produto.
Não há cortes, não há limitações técnicas, não há priorização.

É o destino final.

O caminho até aqui será definido em sessões futuras de:
1. **MVP Definition** — o mínimo pra lançar e validar
2. **Monetização Detalhada** — sessão dedicada
3. **Nome Definitivo** — decisão final
4. **Arquitetura Técnica** — decisões de stack
5. **Design System** — identidade visual completa
6. **Go-to-Market** — estratégia de lançamento

---

*Documento gerado por Bruno Rafante + Maia*
*Versão 1.0 — 2026-03-05*
*Status: Visão completa, aguardando review do Bruno pra enriquecimento*
