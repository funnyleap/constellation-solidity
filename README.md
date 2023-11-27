# constellation-bg

Repositório destinado ao Hackathon Constellation da Chainlink

Sobre o Protocolo

Horizon é um protocolo DEFI que tem por objetivo simplificar o acesso principalmente de pessoas de média-baixa renda ao ecossistema Web3, tornando o processo mais seguro, transparente e auditável. E, com o iminente avanço dos Bens Tokenizados, vamos além implementando uma lógica para que esses Bens possam ser usados como garantias de saque do valor dos Títulos adquiridos. Para tornar isso possível e permitir que seja utilizado em diversas regiões do planeta, além da confiabilidade das ferramentas da Chainlink que serão usadas, a principal barreira que precisa ser derrubada é o onboarding que até pouco tempo atrás era restritivo devido às opções de Carteiras disponíveis. Hoje temos um grande aliado que é o ERC-4337. E esse é o primeiro passo para a mudança nas vidas de muitas pessoas!

Gostaria de entender um pouco mais sobre Bens Tokenizados e sobre o ERC-4337? Acessae os links abaixo:
Bens Tokenizados [RWA] -
Account Abstraction [ERC-4337] -

Aplicação no Hackathon
Essa demonstração realizará a simulação das seguintes etapas:

- Criação dos Títulos;
- Comercialização dos Títuos;
- Pagamentos, atrasos e aplicação de Juros;
- Criação de Permissões de Alocação em diferentes redes;
- Verificação de Garantias;
- Alocação de Garantias e Monitoramento automatizado do valor junto a FIPE.

Ferramentas Usadas

- Chainlink VRF - Verifiable Random Function
  O Chainlink VRF é peça crucial da operabilidade do protocolo, visto que a confiança, transparência e segurança que a ferramenta disponibiliza é fundamental para todas as demais funcionalidades sejam desempenhadas corretamente. A aleatoriedade verificável, segurança criptográfica, decentralização e integração com os Contratos Inteligentes torna os resultados apresentados pela ferramenta inquestionáveis.

- Chainlink CCIP - Cross-Chain Interoperability Protocol
  O Chainlink CCIP possibilita que a Horizon gere inclusão aos mais diversos povos e culturas viabilizando a comunicação entre diversas blockchains e permitindo a integração e utilização de ativos de diferentes locais do globo de forma segura e decentralizada. Na Horizon, específicamente, possibilitará a criação de permissões de alocação de garantias em todas as redes Ethereum compatíveis e, futuramente, poderá integrar o protocolo com redes específicas de cada país.

- Chainlink Functions
  O Chainlink Functions realizará a coleta dos dados necessários para a alocação de Bens de acordo com seus respectivos bancos de dados Offchain. Além disso, futuramente poderá ajudar na tomada de medidas de liquidação ou alertas aos respectivos donos dos ativos alocados no protocolo.
  É responsável pela coleta dos dados junto à FIPE API trazendo onchain dados de automóveis que, serão utilizados como exemplos de ativos tokenizados para garantias.

- Chainlink Automation - Chainlink’s hyper-reliable Automation network
  Chainlink Automation é fundamental para a manutenção do protocolo. Será responsável, junto ao Chainlink functions, pela coleta periódica de dados atualizados das garantias alocadas. Solicitando os dados e armazenando a partir do log de resposta emitido. Dessa forma, o protocolo tem mecanismos que garantem a saúde do ecossistema.
  Além disso, poderá ser utilizado para realizar os sorteios e automatizar processos de um possível novo estágio do protocolo.

- API - Application Programming Interface
  Responsável pela coleta de informações da base da dados da FIPE - Fundação Instituto de Pesquisas Econômicas.

Funcionamento

O protocolo é desenvolvido a partir de contratos inteligentes em Solidity. Esses contratos permitem que a Administração do Protocolo crie Títulos de Consórcio dos mais variados valores e períodos. Esses títulos tem uma quantidade limitada de participantes. Ou seja, cada título tem um número máximo de participantes e isso é definido na sua criação.
Além da quantidade de participantes a política de juros para inadimplentes também pode ser ajustada.

Comercialização dos Títulos

Ao adquirir um título, o cliente tem duas opções principais para o saque:

Saque Imediato
Permite ao cliente sacar o valor imediatamente após ser sorteado.
Taxa de Administração: 10% do valor do título, diluído em parcelas mensais.

Saque Condicionado
O saque só é permitido após o título ultrapassar 50% dos sorteios realizados.
Taxa de Administração: 0%. Por exemplo, se o total de sorteios for 10, o saque só poderá ser feito a partir do sorteio 6, mesmo que o cliente tenha sido sorteado anteriormente.

Investimento dos Valores Recebidos
Uso dos Recursos: Os valores recebidos dos títulos de Saque Condicionado são investidos em protocolos parceiros para gerar receita adicional para a Horizon.
Objetivo: Este processo visa aumentar a sustentabilidade financeira do protocolo e oferecer melhores retornos aos participantes.

Condições de Saque

Condições Gerais
O saque de um título sorteado não é imediato.

O saque está condicionado ao cumprimento de uma das seguintes condições:
Pagamento Total do Título: O valor total do título deve ser pago.
Alocação de Garantias: O cliente pode optar por alocar garantias para liberar o saque.

Opções de Alocação de Garantias
O cliente tem duas opções principais para a alocação de garantias:

Utilização de Títulos Quitados ou Parcialmente Pagos
Títulos que tiveram seu valor totalmente quitado ou com valor pago superior a duas vezes o valor pendente do título no qual a garantia será alocada.
Aplicabilidade: Esta opção é ideal para clientes que possuem outros títulos com pagamentos significativos já realizados.

Utilização de Bens Tokenizados
Bens Tokenizados podem ser usados como garantia para o saque.
Vantagem: Oferece uma alternativa flexível para clientes que possuem ativos digitais tokenizados.

Alocação de Garantias

Após o sorteio de um título, o vencedor tem a opção de alocar garantias para liberar o valor. Esta alocação pode ser feita de duas maneiras principais: usando outros títulos ou utilizando Bens Tokenizados.

Processo de Alocação Usando Títulos
Para usar um título como garantia, o proprietário do título sorteado precisa fornecer algumas informações essenciais:

Identificador do Título Sorteado: Número de identificação do título que foi sorteado.
Identificador do Seu Título Sorteado: Número da sua cota ou participação no título sorteado.
Identificador do Título Usado como Garantia: Número de identificação do título que você deseja usar como garantia.
Identificador da Sua Cota no Título de Garantia: Número da sua cota ou participação no título usado como garantia.

Exemplo Prático:
Título Sorteado: 10
Sua Cota no Título Sorteado: 30
Título para Garantia: 5
Sua Cota no Título de Garantia: 15

Se o valor da cota 15 do título 5 usado como garantia atender aos requisitos necessários, ele será transferido para o protocolo, alocado como garantia da cota 30 do Título 10 e o valor do prêmio será liberado.

Alocação Usando Bens Tokenizados
Bens Tokenizados são ativos digitais que representam a propriedade de um bem real ou virtual. Eles podem ser usados como garantia da seguinte forma:

Compatibilidade de Redes: O Bem Tokenizado pode ser alocado em qualquer rede compatível com o CCIP que a Horizon opere.
Avaliação de Valor: Antes da alocação, o valor do Bem Tokenizado é avaliado através do Chainlink Functions e o API da FIPE. Se for equivalente ou superior ao valor mínimo necessário para o título, ele será aceito como garantia.
Monitoramento Automatizado: Após a alocação, o valor do Bem Tokenizado é monitorado automaticamente. Se houver variações significativas no valor, medidas podem ser tomadas para manter a integridade do protocolo.

Saque do Título
O saque do valor do título é um processo importante no protocolo Horizon e pode ser realizado sob duas condições principais:

Pagamento Total do Título: O saque é permitido após o pagamento integral do valor do título.
Alocação de Garantias: Se garantias forem alocadas conforme as regras do protocolo, o saque também é liberado.

Processo de Saque
Uma vez que uma das condições acima seja atendida, o processo de saque pode ser iniciado:

Iniciativa do Proprietário: Normalmente, o dono do título é quem realiza o saque.
Intervenção Administrativa: Em casos específicos, a administração do protocolo pode transferir o valor do saque diretamente para o dono do título. Isso pode ocorrer por motivos operacionais ou excepcionais definidos pelo protocolo.

Flexibilidade e Segurança
Este sistema de saque foi projetado para oferecer flexibilidade aos usuários, ao mesmo tempo em que mantém a segurança e a integridade do protocolo.

Gestão de Inadimplência e Juros

Política de Pagamento
Datas de Pagamento: As datas de pagamento de cada título são estabelecidas no momento da sua criação.
Flexibilidade Administrativa: A administração do protocolo tem a prerrogativa de postergar as datas de pagamento, se necessário, mas nunca de antecipá-las.

Inadimplência e Aplicação de Juros
Atenção às Datas: É crucial que os clientes estejam atentos às datas de pagamento para evitar inadimplência.
Juros por Atraso: Em caso de atraso no pagamento, os juros previamente definidos serão aplicados. Estes juros são estabelecidos na criação do título e visam manter a saúde financeira do protocolo.
Consequências da Inadimplência: Se o atraso no pagamento exceder duas parcelas, o título será considerado inadimplente e estará sujeito a cancelamento.

Cancelamento de Títulos
Processo de Cancelamento: O cancelamento de um título é uma medida de última instância, aplicada apenas quando há inadimplência significativa.
Impacto do Cancelamento: O cancelamento de um título pode ter implicações financeiras para o titular, incluindo a perda de quaisquer pagamentos já realizados.

Política de Multas

Objetivo das Multas
Função das Multas: As multas são aplicadas em caso de cancelamento de um título para assegurar a estabilidade do protocolo e proteger os interesses dos demais participantes.

Multas em Títulos sem Garantias Alocadas
Cancelamento Pré-Sorteio: Se um título for cancelado antes de ser sorteado e não tiver garantias alocadas, o valor já pago pelo titular será retido como multa.
Finalidade: Esta medida visa compensar o impacto financeiro do cancelamento no pool geral de fundos.

Multas em Títulos com Garantias Alocadas
Cancelamento Pós-Sorteio com Garantia: Para títulos cancelados após o sorteio, nos quais garantias já foram alocadas, a garantia será perdida como multa.
Tratamento da Garantia: A garantia confiscada será vendida no mercado secundário. O valor obtido será utilizado para cobrir a multa correspondente ao título cancelado.

Devolução da Garantia

Após a quitação de todas as parcelas a garantia alocada é retornada ao mesmo endereço responsável pela alocação no Título.

Evolução do Protocolo

Tendo em vista a estrutura apresentada, o protocolo possui um vasto potencial de crescimento e evolução. Entre os pontos que foram discutidos, temos:

1 - Criação do Mercado Secundário para comercialização dos Títulos;
A partir da Criação do Mercado Secundario, os detentores dos Títulos terão a liberdade para comercializá-los. Podendo ocorrer o deságio do título para uma venda rápida em caso de necessidade ou até mesmo o àgio na comercialização de um título que foi sorteado. A partir disso o protocolo ganha com crescimento da liquidez, o mercado poderá precificar os Títulos de forma dinâmica a partir da oferta e demanda, tornando o processo mais justo e transparente.
Além disso, abre se uma porta para que clientes diversifiquem seu portfólio de investimento, reduz a inadimplência, facilita o acesso a novos participantes e estimula a participação uma vez que, apesar de ter assumido o compromisso, o participante poderá repassar o seu título se necessário.
Por fim, a introdução de um mercado secundário pode levar a inovações adicionais e ao crescimento do ecossistema Horizon, atraindo mais usuários e investidores e aumentando a robustez e a resiliência do sistema.

2 - Fomento de parcerias para criação de novas pools para rendimento dos valores bloqueados;
O desenvolvimento de novas parcerias pode gerar inúmeros benefícios estratégicos e operacionais, ampliando o alcance do Protocolo. Entre elas, temos:

- O acesso a novos mercados a partir de outros protocolos de DeFi ou finanças tradicionais aumentando considerávelmente o número de usuários.
- Expansão de Recursos e Diversificação de Investimentos adequando a ofertas e demandas regionais.
- Sustentabilidade a Longo Prazo fornecendo estabilidade e inovação contínua.

3 - Serviços de Empréstimo utilizando os Bens Tokenizados como Garantia

- Amplia a área de atuação da Horizon para países com taxas de juros mais baixas onde, inicialmente, o consórcio não seria uma opção viável;
- Facilita o acesso a liquidez de Curto prazo a partir do Bens Tokenizados;
- Taxas de juros mais baixas a partir da garantia alocada;
- Eficiência no processo;
- Gerar liquidez para o mercado de Bens Tokenizados;
- Crescimento do protocolo a medida que mais bens são Tokenizados ao redor do mundo.

Chainlink Data Streams seria uma ferramenta crucial para o correto funcionamento do protocolo. Assim como poderá ser usado com para monitoramento dos Bens Tokenizados.

4 - Financiamentos utilizando os Bens Tokenizados como Garantia.

- Acesso fácil e rápido a capital principalmente para empreendedores;
- Acesso a Financiamentos para grandes compras como imóveis, móveis, equipamentos no geral.
- Devido a natureza garantida, podemos oferecer condições de financiamento favoráveis como taxas de juros mais baixas e prazos de pagamento dinâmicos à necessidade.

Todos os possíveis cenários apresentados convergem para processos eficientes e transparentes a partir da tecnologia empregada e geram inclusão financeira para pessoas e empresas que não tem acesso à empréstimos em instituições tradicionais, mas dispõe de bens e precisam gerar valor a partir deles.

Em resumo, o produto inicial e seus possíveis desdobramentos não só é útil para investidores, como também será para pessoas que em momento de necessidade podem atender demandas específicas como questões de saúde adquirindo empréstimos, financiamentos de forma rápida e prática utilizando seus bens como garantia.

Conclusão

A Horizon representa um avanço significativo na democratização do acesso ao ecossistema Web3, com um foco especial na inclusão financeira de indivíduos de média e baixa renda. Ao integrar tecnologias inovadoras como Chainlink VRF, CCIP, Functions e Automation, e a integração com a Tabela FIPE, a Horizon estabelece um novo padrão em termos de segurança, transparência e auditabilidade em operações financeiras descentralizadas.

Através da implementação de um sistema robusto de consórcios, o Horizon não apenas facilita a aquisição de bens e serviços, mas também abre caminho para o uso eficiente de Bens Tokenizados como garantias, ampliando as possibilidades de saque e investimento para os usuários. Este aspecto é particularmente revolucionário, pois alavanca o potencial dos ativos digitais de uma maneira que beneficia diretamente o usuário final, ao mesmo tempo em que mantém a integridade e a sustentabilidade do sistema.

Além disso, a estrutura da Horizon está desenhada para evoluir e se adaptar às necessidades emergentes do mercado e dos usuários. Com planos futuros que incluem a criação de um mercado secundário para títulos, a exploração de parcerias para rendimentos adicionais, e a expansão para serviços de empréstimo e financiamento, a Horizon não é apenas uma solução para o presente, mas um investimento no futuro da finança descentralizada.

Sessão do Desenvolvedor

Smart contracts
Horizon[]
HorizonS[]
HorizonStaff[]
HorizonVRF[]
HorizonFujiR[]
HorizonFujiS[]
HorizonFunctions[]
HorizonFujiAssistant[]
FakeRWA[]

Blockchains
Polygon[]
Avalanche[]

Tools
Chainlink Automation[https://docs.chain.link/chainlink-automation]
Chainlink CCIP[https://docs.chain.link/ccip]
Chainlink Functions[https://docs.chain.link/chainlink-functions]
Chainlink VRF[https://docs.chain.link/vrf]

API
API GitHub Repository[https://github.com/deividfortuna/fipe].
API_Key: https://parallelum.com.br/fipe/api/v1/${tipoAutomovel}/marcas/${idMarca}/modelos/${idModelo}/anos/${dataModelo}
Input used in demo - ["motos","77","5223","2015-1"].

Body
{
"codigoTipoVeiculo": motos,
"idMarca": 77,
"idModelo": 5223,
"dataModelo": "2015-1",
}

Response
{
"TipoVeiculo": 2,
"Valor": "R$ 41.761,00",
"Marca": "HARLEY-DAVIDSON",
"Modelo": "XL 883N IRON",
"AnoModelo": 2015,
"Combustivel": "Gasolina",
"CodigoFipe": "810052-7",
"MesReferencia": "novembro de 2023",
"SiglaCombustivel": "G"
}
