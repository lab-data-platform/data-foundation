# CLAUDE.md — data-foundation

Repositório da base da plataforma `lab-data`. Regras gerais, arquitetura e contratos ficam no hub: [../data-platform/CLAUDE.md](../data-platform/CLAUDE.md). Leia esse arquivo primeiro.

## Específico deste repositório

- `bootstrap/`: cria o bucket de state usado por **todos** os repositórios. State local, `prevent_destroy`. Não rode `destroy` nele.
- `infra/`: stack principal, com state em `foundation/<env>/terraform.tfstate` (configurado no `make init`).
- Tudo o que outro repositório precisa deste vai para `infra/contract.tf` (SSM `/lab-data/<env>/foundation/*`). Ao mudar o contrato, atualize `data-platform/docs/contratos.md` e o teste `contrato_publica_os_parametros_esperados`.
- Antes de entregar uma mudança: `make fmt` e `make test`.
- `apply`, `destroy` e `bootstrap-apply` só com confirmação explícita do usuário.
