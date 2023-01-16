git clone https://github.com/DiegoRX/dex-contracts

install node js LTS: 
https://nodejs.org/en/

install truffle:
npm i -g truffle

install dependencies:
npm install

En el archivo truffle-config.js añade tu llave privada de metamask desde la cual harás los despliegues
Tu llave estará segura siempre y cuando no subs tu c+odigo a internet

Deploy to testnet:
truffle migrate --network mumbai --reset

Deploy to Mainnet:
truffle migrate --network polygon --reset