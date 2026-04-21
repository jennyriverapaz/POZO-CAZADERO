// api/webhook.js

export default async function handler(req, res) {
  if (req.method === 'POST') {
    const paymentInfo = req.query; 

    // Verificamos si Mercado Pago nos avisa de un pago
    if (paymentInfo.type === 'payment') {
      const paymentId = paymentInfo['data.id'];
      
      try {
        // 1. Preguntarle a Mercado Pago los detalles de este pago (para sacar la metadata)
        // OJO: Reemplaza "TU_ACCESS_TOKEN_DE_MERCADO_PAGO" con el tuyo
        const mpResponse = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
          headers: { 'Authorization': `Bearer MERCADOPAGO_ACCESS_TOKEN` }
        });
        const paymentData = await mpResponse.json();

        // Si el pago está aprobado
        if (paymentData.status === 'approved') {
          // 2. Sacamos los datos secretos que escondimos
          const reciboId = paymentData.metadata.recibo_id;
          const tokenCiudadano = paymentData.metadata.token_ciudadano;

          // 3. ¡Llamamos a Hydra simulando ser la app!
          const hydraUrl = `https://hydra-real.vercel.app/api/ciudadanos/me/recibos/${reciboId}/pagar`;
          
          const hydraResponse = await fetch(hydraUrl, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${tokenCiudadano}`
            },
            body: JSON.stringify({
              metodo_pago: "externo",
              referencia_externa: `MP_${paymentId}`
            })
          });

          if (hydraResponse.ok) {
            console.log(`¡Éxito! Recibo ${reciboId} marcado como pagado en Hydra.`);
          } else {
            console.error(`Error al avisar a Hydra:`, await hydraResponse.text());
          }
        }
      } catch (error) {
        console.error("Error procesando webhook:", error);
      }
    }

    // Siempre responder 200 a Mercado Pago rápido
    return res.status(200).send('OK');
  }

  res.status(405).send('Método no permitido');
}