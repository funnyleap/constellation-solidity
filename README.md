# constellation-bg
Repositório destinado ao Hackathon Constellation da Chainlink

API GitHub Repository - https://github.com/giovanigenerali/fipe-json
Consultar Veículo pelo Código FIPE

Headers
Host: veiculos.fipe.org.br
Referer: http://veiculos.fipe.org.br
Content-Type: application/json

Body
{
  "codigoTabelaReferencia": 263,
  "codigoTipoVeiculo": 2,
  "anoModelo": 2015,
  "modeloCodigoExterno": "810052-7",
  "codigoTipoCombustivel": 1,
  "tipoConsulta": "codigo"
}

Response
{
  "Valor": "R$ 30.054,00",
  "Marca": "HARLEY-DAVIDSON",
  "Modelo": "XL 883N IRON",
  "AnoModelo": 2015,
  "Combustivel": "Gasolina",
  "CodigoFipe": "810052-7",
  "MesReferencia": "dezembro de 2020 ",
  "Autenticacao": "ppp4h1k49svv",
  "TipoVeiculo": 2,
  "SiglaCombustivel": "G",
  "DataConsulta": "sexta-feira, 17 de novembro de 2023 09:49"
}
