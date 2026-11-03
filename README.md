# Zoo das Cores

Abra o project.godot da raiz no Godot e execute a cena principal.

O fundo existente foi mantido. Cachorro, leão e dinossauro começam sem cores. A história aparece na abertura e é narrada quando houver uma voz portuguesa instalada no sistema.

## Entrada da câmera

Por padrão, o aplicativo verifica `godot/dados_json` a cada 0,75 segundo. A câmera pode substituir `leitura.json` ou criar novos arquivos `.json`. A pasta é configurável na propriedade `pasta_json` do nó Floresta no Inspector. Para usar C:/fotos, crie essa pasta e selecione-a, ou inicie o jogo com `-- --pasta-json=C:/fotos`.

Formato aceito:

```json
{
  "tipo": "asas.leitura",
  "lido_em": "2026-10-23T14:23:35",
  "desenhos": [
    { "id": "100", "nome": "cachorro", "cores": ["bege"] },
    { "id": "997", "nome": "leao", "cores": ["laranja", "amarelo"] },
    { "id": "111", "nome": "dinossauro", "cores": ["verde"] }
  ]
}
```

`desenhos: []` é válido e não apaga os animais já pintados. Reinicie o jogo com os arquivos vazios para começar uma nova atividade. Os nomes identificam os animais; os IDs não precisam coincidir com a folha impressa. Não é necessário enviar `validado`.

São aceitas até três cores nas regiões ilustrativas do animal. Como o JSON não informa qual região recebeu cada cor, a posição das cores é aproximada. Os desenhos na tela são ilustrações vetoriais próprias, não reproduções exatas das folhas fornecidas.

Cores: bege, amarelo, laranja, verde, azul, marrom, rosa, roxo, vermelho, branco, preto e cinza. Leituras desconhecidas ou incompletas são ignoradas. Arquivos com JSON ainda em gravação são tentados novamente. Recomenda-se gravar em arquivo temporário e renomeá-lo para `.json` ao terminar.

A leitura funciona enquanto o aplicativo está aberto. A captura e o reconhecimento da câmera são feitos pelo sistema externo.
# Dinâmica da história

A aventura segue a ordem **cachorro → dinossauro → leão**. A nuvem Nublina, distraída, tropeçou num arco-íris e engoliu as cores da Floresta dos Abraços. A criança ajuda Pipoca, Dino e Léo a recuperá-las.

- **Começo dramático:** a floresta está cinza e escura, a Nublina cobre o sol e chove de leve. Os animais respiram devagar, suspiram e choram. O amigo da vez fica iluminado e chora mais.
- **Cenário vivo:** as copas das árvores e a grama balançam com o vento (shader `godot/shaders/floresta.gdshader`), rajadas aparecem de vez em quando, folhas voam e o lago treme.
- **Transformação:** quando o JSON chega, a Nublina solta uma bola de cor que voa até o animal. A cor se espalha a partir do centro dele, com estrelas e tinta. Depois ele pula de alegria, muda a expressão (sorriso, bochechas e brilho nos olhos) e solta corações.
- **A floresta revive:** a cada amigo pintado, o fundo recupera parte da cor, a Nublina clareia e se afasta do sol, e a música fica mais alegre. No final aparecem um arco-íris, confetes e uma dancinha de todos.
- Se o animal for pintado de novo, a cor é atualizada com uma nova explosão.
- Se a criança demorar, o narrador dá um incentivo (uma vez por capítulo).

Leituras de animais de etapas futuras ficam guardadas até chegar sua vez. Um JSON vazio não avança a atividade nem apaga as pinturas.

## Narração

As falas ficam em `godot/assets/narracao/roteiro.json` e foram gravadas com voz neural (pt-BR Francisca, 12% mais rápida). Para mudar o texto ou a voz:

```
pip install edge-tts truststore
python tools/gerar_narracao.py                       # todas as falas
python tools/gerar_narracao.py cap_leao final_1      # só algumas
python tools/gerar_narracao.py --voz pt-BR-ThalitaMultilingualNeural --velocidade +15%
```

Depois de gerar, abra o projeto no Godot para importar os áudios. Se faltar algum `.mp3`, a fala usa a melhor voz portuguesa do Windows. Os efeitos sonoros (`magia`, `sopro`, `vento` e `pop`) são sintetizados por `tools/gerar_efeitos.py`.
