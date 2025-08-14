# 🔐 Cofre Digital com FSM (FPGA)

Projeto de uma máquina de estados finitos (FSM) em SystemVerilog que implementa um cofre digital com senha de 3 dígitos, modo de programação seguro e bloqueio temporizado, otimizado para a placa FPGA DE2-115.

![Diagrama da Máquina de Estados](docs/diagrama_fsm.jpg)

## ✅ Funcionalidades

* Validação de senha numérica de 3 dígitos.
* Contador de erros que ativa o bloqueio do sistema após 3 falhas.
* Modo de programação para definir a senha, acessível apenas após o cofre ser destravado (exceto no primeiro uso).
* Bloqueio temporário de 10 segundos após 3 tentativas incorretas.
* Timeout de 10 segundos no estado destravado, retornando ao estado ocioso por segurança.
* Indicação visual clara e minimalista:
    * LED Verde (`led_green`): Indica que o cofre está destravado.
    * LED Vermelho (`led_red`): Indica que o cofre está bloqueado.

## 🧱 Estrutura do Sistema

O projeto é implementado como uma FSM com **codificação binária** para eficiência, utilizando os seguintes estados:

| Estado      | Função                                                              |
| :---------- | :------------------------------------------------------------------ |
| `S_IDLE`    | Estado ocioso, aguardando entrada ou o modo de programação.         |
| `S_PROGRAM` | Modo de programação ativo, capturando os 3 dígitos da nova senha.   |
| `S_INPUT`   | Recebendo a tentativa de senha de 3 dígitos do usuário.             |
| `S_CHECK`   | Compara a senha inserida com a senha armazenada.                    |
| `S_UNLOCKED`| Senha correta, cofre destravado por 10 segundos.                    |
| `S_LOCKED`  | 3 senhas incorretas, cofre bloqueado por 10 segundos.               |

## 🔌 Entradas e Saídas

### Entradas

* `clk` → Clock do sistema (50 MHz).
* `rst` → Reset geral do sistema (ativo alto).
* `prog_sw` → Chave para habilitar o modo de programação (nível alto).
* `btn_n[3:0]` → Botões (ativos em baixo) para entrada dos dígitos.

### Saídas

* `led_green` → Acende quando o cofre está no estado `S_UNLOCKED`.
* `led_red` → Acende quando o cofre está no estado `S_LOCKED`.

## ⏳ Lógica de Bloqueio e Timeout

* **Bloqueio por Erro:** Quando 3 tentativas incorretas ocorrem, o estado `S_LOCKED` é ativado. O `led_red` acende e um contador de 10 segundos é iniciado. Ao final, o sistema retorna a `S_IDLE`.
* **Timeout de Desbloqueio:** Quando o estado `S_UNLOCKED` é ativado, o `led_green` acende e um contador de 10 segundos é iniciado. Se nenhuma ação for tomada, o sistema retorna a `S_IDLE` como medida de segurança.

## ▶️ Como Usar

1.  Compile o arquivo `safecrack_fsm_diagrama_final.sv` no Quartus Prime.
2.  Use o **Pin Planner** para associar as entradas e saídas aos pinos físicos da sua placa DE2-115.
3.  Crie um arquivo **SDC** (`.sdc`) para definir o clock de 50 MHz.
4.  Use a ferramenta **Programmer** para gravar o arquivo `.sof` gerado na placa.
5.  Teste o funcionamento usando os switches e botões.

## 💡 Observações

* **Sem Senha Padrão:** Por segurança, o sistema não possui senha padrão. No primeiro uso, é obrigatório ativar o modo de programação (`prog_sw`) para definir a primeira senha.
* **Reset:** Para resetar a máquina de estados, ative a chave `rst`.
* **Alterar a Senha:** Para alterar a senha, primeiro destrave o cofre com a senha atual, e então ative a chave `prog_sw` para entrar no modo de programação.
* **Bloqueio:** Após 3 erros de senha completa, o sistema entra no estado `S_LOCKED`.
