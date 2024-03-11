
assuembly_code = [
    "IMM 62 0",
    
    "IMM 63 72",
    "BNE 2 63 62",
    
    "IMM 63 101",
    "BNE 4 63 62",
    
    "IMM 63 108",
    "BNE 6 63 62",
    
    "IMM 63 108",
    "BNE 8 63 62",
    
    "IMM 63 111",
    "BNE 10 63 62",
    
    "IMM 63 32",
    "BNE 12 63 62",

    "IMM 63 87",
    "BNE 14 63 62",

    "IMM 63 111",
    "BNE 16 63 62",

    "IMM 63 114",
    "BNE 18 63 62",

    "IMM 63 108",
    "BNE 20 63 62",

    "IMM 63 100",
    "BNE 22 63 62",

    "IMM 63 13",
    "BNE 24 63 62",

    "IMM 63 10",
    "BNE 26 63 62",
]




def assemble_instruction(instruction):
    """
    Assemble a single assembly instruction into a 32-bit binary string based on specific logic.
    
    Args:
    instruction (str): The instruction string (e.g., "IMM 10 100").
    
    Returns:
    str: The 32-bit binary representation of the instruction.
    """
    # Split the instruction into parts
    parts = instruction.split()
    op = parts[0]  # Operation name
    
    if  len(parts) == 3:
        b = 0
        a = int(parts[1])  # First operand
        c = int(parts[2])
    elif len(parts) == 4:
        a = int(parts[1])
        b = int(parts[2])  # Second operand
        c = int(parts[3])  # Destination register
    
    # Define operation codes
    op_codes = {
        "IMM": "0011",
        "ADD": "0001",
        "SUB": "0010",
        "BNE": "0100"
    }
    
    # Convert the parts of the instruction into binary strings
    binary_a = format(a, '08b')  # Convert a to an 8-bit binary
    binary_b = format(b, '08b')  # b is not used, set to 0
    binary_c = format(c, '08b')  # Convert c to an 8-bit binary
    
    # Concatenate the binary strings
    binary_instruction = op_codes[op] + binary_a + binary_b + binary_c
    
    # Pad the instruction to 32 bits
    binary_instruction = binary_instruction.ljust(32, '0')
    
    return binary_instruction


for instruction in assuembly_code:
    print(assemble_instruction(instruction))
