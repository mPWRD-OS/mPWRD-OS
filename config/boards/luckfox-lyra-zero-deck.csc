# Build the deck board from the Lyra Zero W board definition, then override
# only the board identity so it behaves as a separate device target.
deck_base_board_file="${USERPATCHES_PATH}/config/boards/luckfox-lyra-zero-w.csc"
[[ -f "${deck_base_board_file}" ]] || deck_base_board_file="${SRC}/config/boards/luckfox-lyra-zero-w.csc"
source "${deck_base_board_file}"

BOARD_NAME="Luckfox Lyra Zero Deck"
