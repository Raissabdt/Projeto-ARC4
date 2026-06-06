# Script de compilação e execução automática

# Deleta a pasta work antiga se ela existir, para evitar erros de data
if {[file exists work]} {
    vdel -lib work -all
}

# Cria uma biblioteca 'work' limpa e nova
vlib work

# Compilação na ordem correta
vcom Util_pkg.vhd
vcom GenerateKeyStream_pkg.vhd

vcom RegisterNbits.vhd
vcom Memory.vhd

vcom controlPath.vhd
vcom dataPath.vhd

vcom GenerateKeyStream.vhd
vcom GenerateKeyStream_tb.vhd

# Inicia a simulação
vsim work.GenerateKeyStream_tb

# Configura a janela de ondas
add wave -r /*
config wave -signalnamewidth 1

# Roda o tempo
run 1250 ns

# Ajusta o zoom automaticamente para caber na tela
wave zoom full