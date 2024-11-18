// Importa os módulos necessários usando ESM
import { createRemoteJWKSet, jwtVerify } from 'jose';
import { CognitoIdentityProviderClient, AdminGetUserCommand } from '@aws-sdk/client-cognito-identity-provider';
import CryptoJS from 'crypto-js';

const region = process.env.REGION;
const userPoolId = process.env.USER_POOL_ID;
const cognitoIssuer = `https://cognito-idp.${region}.amazonaws.com/${userPoolId}`;

const client = new CognitoIdentityProviderClient({ region: 'us-east-1' });

async function verifyToken(token) {
  try {
    // Obter as chaves públicas do JWKS (de forma remota)
    const JWKS = createRemoteJWKSet(new URL(`${cognitoIssuer}/.well-known/jwks.json`));

    // Verificar o token
    const { payload } = await jwtVerify(token, JWKS, {
      issuer: cognitoIssuer,
    });

    const user = await getUserData(payload.username)
    return user;
  } catch (error) {
    console.error('Token inválido:', error.message);
    throw new Error('Token inválido:', error.message)
  }
}

async function getUserData(username) {
  try {
    const command = new AdminGetUserCommand({
      UserPoolId: userPoolId,
      Username: username,
    });

    // Executa o comando e obtém a resposta
    const response = await client.send(command);

    const reformulatedObject = reformulateUserAttributes(response.UserAttributes);
    reformulatedObject.user_name = username;
    return reformulatedObject;
  } catch (error) {
    console.error('Erro ao buscar o usuário:', error.message);
    throw new Error('Erro ao buscar o usuário::', error.message)
  }
}

function reformulateUserAttributes(userAttributes) {
  return userAttributes.reduce((acc, attribute) => {
    acc[attribute.Name] = attribute.Value;
    return acc;
  }, {});
}

function encryptObject(object) {
  const jsonString = JSON.stringify(object); // Converte o objeto em string JSON
  console.log(jsonString)
  const encrypted = CryptoJS.AES.encrypt(
    jsonString,
    process.env.SECRET_KEY_CRYPTO,
  ).toString(); 

  return encrypted;
}

// Função handler da AWS Lambda
export const handler = async (event) => {
  console.log('*****************************')
  console.log(event)
  
  const token = event.authorizationToken;  // Supondo que o token JWT esteja no body do evento

  if (!token) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: 'Token not provided' }),
    };
  }

  try {
    let verifiedToken;
    if(event.methodArn.includes('public/') && token.length < 128 && token.length > 10){
      try {
        verifiedToken = await getUserData(token);
      } catch (error) {
        console.log(error)
        throw new Error('Erro ao buscar por cpf >>> ', error.message)
      }
      console.log('>>>>>>>>>', verifiedToken)
    } else {
      verifiedToken = await verifyToken(token);
      console.log('XXXXXXXXXXx', verifiedToken)
    }
    const userCrypto = encryptObject(verifiedToken);
    console.log(userCrypto)
    console.log(verifiedToken)

    const authResponse = {
      principalId: verifiedToken.user_name,
      policyDocument: {
          Version: '2012-10-17',
          Statement: [{
              Action: 'execute-api:Invoke',
              Effect: 'Allow',
              Resource: event.methodArn
          }]
      },
      context: {
        user: userCrypto
      }
    };
    return authResponse;
  } catch (error) {
    console.log('error>>>>', error)
    return {
      principalId: 'user',
      policyDocument: {
          Version: '2012-10-17',
          Statement: [{
              Action: 'execute-api:Invoke',
              Effect: 'Deny',
              Resource: event.methodArn,
          }],
      },
      context: {
          error: error.message,
      },
  };
  }
};
