# A Magia das Cores: Floresta Encantada

Abra o project.godot da raiz no Godot e execute a cena principal.

O fundo existente foi mantido. A onça, o macaco, o tamanduá e a borboleta começam cinza, escondidos atrás das moitas. A história segue a especificação "MESA EDUCACIONAL - A magia das cores" (cenário 1, Floresta Encantada). Ela aparece na abertura e é narrada.

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
    { "id": "13", "nome": "tamandua", "cores": ["preto"] },
    { "id": "12", "nome": "borboleta", "cores": ["vermelho"] }
  ]
}
```

`desenhos: []` é válido e não apaga os animais já pintados. Reinicie o jogo com os arquivos vazios para começar uma nova atividade. Os nomes identificam os animais, com ou sem acento (`onça` ou `onca`, `tamanduá` ou `tamandua`). Os IDs não precisam coincidir com a folha impressa. Não é necessário enviar `validado`.

São aceitas até três cores. A primeira pinta a maior parte do animal e as outras se alternam nas demais regiões. Como o JSON não informa qual região recebeu cada cor, a posição é aproximada. Qualquer cor é aceita; a narração pede a cor da especificação.

Os desenhos na tela são os mesmos dos cartões impressos (`floresta_encantada_8x8_4_na_folha_v2.pdf`). Para gerá-los de novo, ou para outra folha no mesmo formato, como a Fazenda Feliz:

```
pip install pypdf pillow numpy scipy
python tools/preparar_animais.py floresta_encantada_8x8_4_na_folha_v2.pdf macaco borboleta tamandua onca
```

Cores: bege, amarelo, laranja, verde, azul, marrom, rosa, roxo, vermelho, branco, preto e cinza. Leituras desconhecidas ou incompletas são ignoradas. Arquivos com JSON ainda em gravação são tentados novamente. Recomenda-se gravar em arquivo temporário e renomeá-lo para `.json` ao terminar.

A leitura funciona enquanto o aplicativo está aberto. A captura e o reconhecimento da câmera são feitos pelo sistema externo.
# Dinâmica da história

A aventura segue a ordem **onça amarela → macaco marrom → tamanduá preto → borboleta vermelha**. O vento forte da madrugada levou as cores da Floresta Encantada, e os animais, com medo, esconderam-se atrás da vegetação. A sábia Coruja pede ajuda às crianças.

- **Começo dramático:** a floresta está cinza e escura, uma nuvem carregada cobre o sol e chove de leve. Cada animal espia por cima da sua moita, treme, se abaixa e solta gotinhas de medo. O animal da vez fica iluminado e a moita dele chacoalha.
- **Cenário vivo:** as copas das árvores e a grama balançam com o vento (shader `godot/shaders/floresta.gdshader`), rajadas aparecem de vez em quando, folhas voam e o lago treme. A Coruja pisca e balança no galho.
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

Depois de gerar, abra o projeto no Godot para importar os áudios. Se faltar algum `.mp3`, a fala usa a melhor voz portuguesa do Windows. Os efeitos sonoros (`magia`, `sopro`, `vento` e `pop`) são sintetizados por `tools/gerar_efeitos.py`.
