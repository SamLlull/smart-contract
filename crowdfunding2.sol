// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TokenVerifier {
    // El contrato Crowdfunding que contiene la información de los tokens
    Crowdfunding public crowdfundingContract;

    event VerificacionExitosa(address financiador, string mensaje);

    constructor(address _crowdfundingContract) {
        // Aquí se establece la dirección del contrato Crowdfunding
        crowdfundingContract = Crowdfunding(_crowdfundingContract);
    }

    // Función para verificar la contribución mediante un token
    function verificarToken(uint256 token) public {
        uint256 tokensFinanciador = crowdfundingContract.tokens(msg.sender);

        require(tokensFinanciador >= token, "No tienes suficientes tokens");

        emit VerificacionExitosa(msg.sender, "Contribucion verificada exitosamente!");
    }
}

contract Crowdfunding {
    mapping(address => uint256) public financiadores;
    mapping(address => uint256) public tokens;
    uint256 public deadline;
    uint256 public objetivosFondos;
    string public nombre;
    address public propietario;
    bool public fondosRetirados;
    
    event Financiado(address _financiador, uint256 _importe);
    event RetiradaFondosPropietario(uint256 _importe);
    event RetiradaFondosFinanciador(address _financiador, uint256 _importe);
    event TokenOtorgado(address _financiador, uint256 _cantidad);
    
    constructor(string memory _nombre, uint256 _objetivosFondos, uint256 _deadline) {
        propietario = msg.sender;
        nombre = _nombre;
        objetivosFondos = _objetivosFondos;
        deadline = _deadline;
    }

    function fondo() public payable {
        // Verifica que el fondo esté habilitado y que el objetivo aún no se haya alcanzado
        require(verificarFondoHabilitado() == true, "Fondo no habilitado");
        

        // Verifica que la contribución no exceda el objetivo
        uint256 balanceActual = address(this).balance;
        uint256 contribucionPermitida = objetivosFondos - balanceActual;
        require(msg.value > contribucionPermitida, "Contribucion excede el objetivo");

        financiadores[msg.sender] += msg.value;
        emit Financiado(msg.sender, msg.value);

        // Otorgar token al contribuyente
        otorgarToken(msg.sender, 1); // Otorga 1 token por contribución
    }

    function otorgarToken(address _financiador, uint256 _cantidad) internal {
        tokens[_financiador] += _cantidad;
        emit TokenOtorgado(_financiador, _cantidad);
    }

    function retiradaCantidadPropietario() public {
        require(msg.sender == propietario, "NO ESTA AUTORIZADO!");
        require(verificarFondoCompletado() == true, "NO PUEDE RETIRAR LA CANTIDAD");

        uint256 importeAEnviar = address(this).balance;
        (bool success,) = msg.sender.call{value: importeAEnviar}("");
        require(success, "NO SE PUEDE ENVIAR!");
        fondosRetirados = true;
        emit RetiradaFondosPropietario(importeAEnviar);
    }

    function retiradaCantidadFinanciador() public {
        require(verificarFondoHabilitado() == false && verificarFondoCompletado() == false, "NO ADMISIBLE!");

        uint256 importeAEnviar = financiadores[msg.sender];
        (bool success,) = msg.sender.call{value: importeAEnviar}("");
        require(success, "NO SE PUEDE ENVIAR!");
        financiadores[msg.sender] = 0;
        emit RetiradaFondosFinanciador(msg.sender, importeAEnviar);
    }

    // Funciones auxiliares
    function verificarFondoHabilitado() public view returns(bool) {
        if (block.timestamp > deadline || fondosRetirados) {
            return false;
        } else {
            return true;
        }
    }

    function verificarFondoCompletado() public view returns(bool) {
        if(address(this).balance >= objetivosFondos || fondosRetirados) {
            return true;
        } else {
            return false;
        }
    }

}