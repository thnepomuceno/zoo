# A Magia das Cores

Abra o project.godot da raiz no Godot e execute a cena principal. Ela abre o **carrossel** com os 4 cenários da especificação "MESA EDUCACIONAL - A magia das cores". Use as setas (ou ← →, ou 1 a 4) e escolha o modo de pintura:

- **Pintura com cores predefinidas** (Enter ou P): a narração diz qual cor usar em cada animal (a onça amarela, o macaco marrom...).
- **Pintura com cores livres** (L): a criança pinta cada animal com as cores que quiser. As placas e a narração não falam de cor (falas `*_livre` em `roteiro.json`). Para abrir direto neste modo: `-- --cores-livres`.

 Na aventura, o botão **Cenários** (ou Esc) volta ao carrossel. Para abrir um cenário direto: `-- --cenario=fazenda`.

**Uma atividade só:** passe o número da atividade ao executável, por exemplo `aplica.exe -1`. O carrossel mostra apenas aquele cenário (sem setas nem bolinhas); o botão **Cenários** volta para ele. Sem parâmetro, aparecem todos. Também vale `-2`, `-3`, `-4`, `--atividade=2` ou o nome (`-fazenda`). No editor, coloque depois de `--` (ex.: `-- -1`).

**Cor diferente da pedida (cores predefinidas):** se o cartão chega sem a cor pedida, a tela e a narração avisam ("Oi! Foi pedida a onça na cor amarela. Mas você pintou de azul!"), mostram a cor pedida ao lado da pintada e perguntam se a criança quer tentar de novo:
- **CANCELAR** (botão vermelho, Backspace ou R): o cartão é descartado e o jogo espera um novo cartão em branco pintado na cor sugerida. O mesmo cartão, se a câmera mandar de novo nos 6 segundos seguintes, é ignorado.
- **CONTINUAR** (botão verde, Enter ou G): "Certo, vamos prosseguir com a cor que você escolheu!" O animal sai com a cor pintada, e a placa, a festa e a apresentação do nome deixam de citar a cor pedida.

O cartão vale quando a cor pedida aparece entre as cores lidas (a onça amarela com pintas pretas passa). A **tecla J** simula um cartão com a cor errada.

- **1 · Floresta Encantada:** a onça, o macaco, o tamanduá e a borboleta começam cinza, escondidos atrás das moitas. A sábia Coruja pede ajuda.
- **2 · Fazenda Feliz:** a tempestade levou as cores e a nuvem triste cobre o sol. O cavalo marrom, o porco rosa, o pato amarelo e a galinha laranja estão escondidos atrás dos fardos de feno, e o sábio Galo pede ajuda em cima da cerca. A cada animal, a nuvem se afasta do sol e fica mais alegre. No final, ela sorri e o sol volta a brilhar.
- **3 · Lagoa Cristalina:** a sujeira da fábrica roubou as cores da lagoa e a fumaça cobre o sol. O sapo verde e a capivara marrom estão atrás dos juncos; o peixe azul e a cobra amarela, atrás das pedras. O Pato Sabido, de óculos, pede ajuda boiando na lagoa.
- **4 · Aventura Marinha:** a poluição escureceu o fundo do mar. A baleia azul e a tartaruga verde estão atrás das pedras; o peixe laranja e o boto cor-de-rosa, entre as algas. O Senhor Polvo, de chapéu, pede ajuda em cima da pedra grande. O mar começa bem escuro, tudo ondula, sobem bolhas e a luz dança no fundo.

**Nomes dos amigos (todos os cenários):** quando o último animal aparece e a narração final acaba, o foco vai para o primeiro animal (holofote e setinha em cima) e o cursor fica no campo **QUAL O NOME DESTE AMIGO?**. A criança escreve pelo teclado e aperta **OK** ou Enter; o nome vai para a placa e o foco passa para o próximo. Depois do último, o narrador apresenta todos ("O sapo verde se chama Lili!"). Os nomes são falados pela voz portuguesa do Windows, porque não dá para gravá-los antes.

Os cenários (história, animais, ajudante e posições) ficam em `godot/scenes/cenarios.gd`. A história aparece na abertura e é narrada.

## Entrada da câmera

Por padrão, o aplicativo verifica `godot/dados_json` a cada 0,75 segundo. A câmera pode substituir `leitura.json` ou criar novos arquivos `.json`. A pasta é configurável na propriedade `pasta_json` do nó Floresta no Inspector. Para usar C:/fotos, crie essa pasta e selecione-a, ou inicie o jogo com `-- --pasta-json=C:/fotos`.

Formato aceito:

```json
{
  "tipo": "asas.leitura",
  "lido_em": "2026-10-23T14:23:35",
  "desenhos": [
    { "id": "14", "nome": "onca", "cores": ["amarelo"] },
    { "id": "11", "nome": "macaco", "cores": ["marrom"] },
    { "id": "13", "nome": "tamandua", "cores": ["marrom"] },
    { "id": "12", "nome": "borboleta", "cores": ["vermelho"] }
  ]
}
```

Na Fazenda Feliz os nomes são `cavalo`, `porco`, `pato` e `galinha`; na Lagoa, `sapo`, `peixe`, `capivara` e `cobra`; no Mar, `baleia`, `peixe`, `tartaruga` e `boto`. Cada cenário ignora os nomes dos outros.

`desenhos: []` é válido e não apaga os animais já pintados. Reinicie o jogo com os arquivos vazios para começar uma nova atividade. Os nomes identificam os animais, com ou sem acento (`onça` ou `onca`, `tamanduá` ou `tamandua`). Os IDs não precisam coincidir com a folha impressa. Não é necessário enviar `validado`.

São aceitas até três cores. A primeira pinta a maior parte do animal e as outras se alternam nas demais regiões. Como o JSON não informa qual região recebeu cada cor, a posição é aproximada. Qualquer cor é aceita; a narração pede a cor da especificação.

Os desenhos na tela são os mesmos dos cartões impressos (`floresta_encantada_8x8_4_na_folha_v2.pdf`). Para gerá-los de novo, ou para outra folha no mesmo formato, como a Fazenda Feliz:

```
pip install pypdf pillow numpy scipy
python tools/preparar_animais.py floresta_encantada_8x8_4_na_folha_v2.pdf macaco borboleta tamandua onca
python tools/preparar_animais.py fazenda_feliz_8x8_4_na_folha.pdf cavalo porco pato galinha
python tools/preparar_animais.py "lagoa_cristalina_8x8_uma_por_folha (1).pdf" sapo peixe_lagoa capivara cobra
python tools/preparar_animais.py aventura_marinha_8x8_uma_por_folha.pdf baleia peixe_mar tartaruga boto
```

Os fundos da Lagoa e do Mar são desenhados por código: `python tools/desenhar_fundos.py` (ou só `lagoa` / `marinha`).

Cores: bege, amarelo, laranja, verde, azul, marrom, rosa, roxo, vermelho, branco, preto e cinza. Leituras desconhecidas ou incompletas são ignoradas. Arquivos com JSON ainda em gravação são tentados novamente. Recomenda-se gravar em arquivo temporário e renomeá-lo para `.json` ao terminar.

A leitura funciona enquanto o aplicativo está aberto. A captura e o reconhecimento da câmera são feitos pelo sistema externo.
# Dinâmica da história

A aventura segue a ordem **onça amarela → macaco marrom → tamanduá marrom → borboleta vermelha**. O vento forte da madrugada levou as cores da Floresta Encantada, e os animais, com medo, esconderam-se atrás da vegetação. A sábia Coruja pede ajuda às crianças.

- **Começo dramático:** a floresta está cinza e escura, uma nuvem carregada cobre o sol e chove de leve. Cada animal espia por cima da sua moita, um pouco menor que o normal (só cresce ao sair do esconderijo), treme, se abaixa e solta gotinhas de medo. O animal da vez fica iluminado e a moita dele chacoalha.
- **Cenário vivo:** as copas das árvores e a grama balançam com o vento (shader `godot/shaders/cenario.gdshader`), rajadas aparecem de vez em quando, folhas voam e o lago treme. A Coruja pisca e balança no galho.
- **Transformação:** quando o JSON chega, a Coruja bate as asas e solta uma bola de cor que voa até o animal. A cor se espalha a partir do centro dele, com estrelas e tinta. A moita chacoalha e solta folhas, e o animal pula para fora do esconderijo e solta corações. A borboleta sai voando.
- **A floresta revive:** a cada animal que aparece, o fundo, as moitas e a Coruja recuperam parte da cor. A nuvem clareia e se afasta do sol, e a música fica mais alegre. No final aparecem um arco-íris e confetes, todos fazem uma dancinha e a Coruja fica feliz.
- Se o animal for pintado de novo, a cor é atualizada com uma nova explosão.
- Se a criança demorar, o narrador dá um incentivo (uma vez por capítulo).
- **Tecla K:** simula a câmera lendo o cartão do animal da vez, pintado com a cor pedida.

Leituras de animais de etapas futuras ficam guardadas até chegar sua vez. Um JSON vazio não avança a atividade nem apaga as pinturas.

## Narração

As falas ficam em `godot/assets/narracao/roteiro.json` e foram gravadas com voz neural (pt-BR Francisca, 12% mais rápida). Para mudar o texto ou a voz:

```
pip install edge-tts truststore
python tools/gerar_narracao.py                       # todas as falas
python tools/gerar_narracao.py cap_onca final_1      # só algumas
python tools/gerar_narracao.py --voz pt-BR-ThalitaMultilingualNeural --velocidade +15%
```

Depois de gerar, abra o projeto no Godot para importar os áudios. Se faltar algum `.mp3`, a fala usa a melhor voz portuguesa do Windows.

Os nomes que as crianças dão aos amigos não podem ser gravados antes. Por isso, assim que cada nome é confirmado, o jogo chama `tools/falar_frase.py` em segundo plano e gera a frase ("A capivara se chama Luna!") com a mesma voz. Os áudios ficam em cache em `user://frases/`. Isso precisa de Python, `edge-tts` e internet na máquina; sem eles, ou no jogo exportado (que não leva a pasta `tools`), os nomes saem pela voz do Windows.

Os efeitos sonoros (`magia`, `sopro`, `vento` e `pop`) são sintetizados por `tools/gerar_efeitos.py`.
