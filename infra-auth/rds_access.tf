########################################
# ACESSO AO RDS
#
# O SG do RDS vive no repositorio techchallenge-ofisy-rds-infra - esta
# regra e criada "de fora", visando o SG dele (via data source em data.tf),
# sem precisar tocar naquele repositorio.
########################################

# Libera a porta 5432 do RDS apenas para a Lambda que emite o token
# (ofisy-auth), que precisa consultar o Postgres pra validar CPF/CNPJ.
# O authorizer NAO precisa disso - nao roda na VPC, nao acessa o banco.
resource "aws_security_group_rule" "rds_postgres_from_lambda_auth" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.lambda_auth.id
  security_group_id        = data.aws_security_group.rds.id
}
