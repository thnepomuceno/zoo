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

A aventura segue a ordem **cachorro → dinossauro → leão**. A nuvem distraída levou as cores da Floresta dos Abraços, e a criança ajuda Pipoca, Dino e Léo a recuperá-las.

Clique em **Vamos pintar!** para começar. Cada capítulo é exibido e narrado, e aguarda o retorno da câmera. O JSON pinta o animal e libera a próxima parte da história. Leituras de animais de etapas futuras ficam guardadas até chegar sua vez. Um JSON vazio não avança a atividade nem apaga as pinturas.

Há música instrumental original em repetição, um efeito de celebração ao receber a pintura, botão para pausar a música e botão para ouvir novamente o capítulo atual. A narração utiliza a voz portuguesa do Windows; uma voz portuguesa foi detectada durante a verificação local.
