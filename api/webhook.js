export default async function handler(req, res) {
  if (req.method === 'POST') {
    // 1. Vemos qué nos mandó Mercado Pago exactamente
    console.log(" 1. Webhook tocado por Mercado Pago. Query:", req.query);

    const paymentInfo = req.query;

    if (paymentInfo.type === 'payment') {
      const paymentId = paymentInfo['data.id'];
      console.log(` 2. Es un pago válido con ID: ${paymentId}`);
      
      try {
        // 3.
        const token = process.env.MERCADOPAGO_ACCESS_TOKEN;
        console.log(" 3. Consultando detalles a Mercado Pago...");
        
        const mpResponse = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        const paymentData = await mpResponse.json();
        
        console.log(` 4. Estado del pago en Mercado Pago: ${paymentData.status}`);

        if (paymentData.status === 'approved') {
          // Extraemos de metadata (usamos ? para evitar errores si viene vacío)
          const reciboId = paymentData.metadata?.recibo_id;
          const tokenCiudadano = paymentData.metadata?.token_ciudadano;
          
          console.log(` 5. Datos ocultos - Recibo: ${reciboId || 'Ninguno'}, Token: ${tokenCiudadano ? 'Sí existe' : 'No existe'}`);

          if (!reciboId || !tokenCiudadano) {
             console.log("Error: Faltan los metadatos. El pago no se enlazará a Hydra.");
          } else {
            const hydraUrl = `https://hydra-real.vercel.app/api/ciudadanos/me/recibos/${reciboId}/pagar`;
            console.log(" 6. Avisando a Hydra en la URL:", hydraUrl);
            
            const hydraResponse = await fetch(hydraUrl, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${tokenCiudadano}` // Nos hacemos pasar por el ciudadano
              },
              body: JSON.stringify({
                metodo_pago: "externo",
                referencia_externa: `MP_${paymentId}`
              })
            });

            if (hydraResponse.ok) {
              console.log(`¡ÉXITO TOTAL! Recibo ${reciboId} marcado como pagado en Hydra.`);
            } else {
              const errorText = await hydraResponse.text();
              console.error(`Error en Hydra (Código ${hydraResponse.status}):`, errorText);
            }
          }
        }
      } catch (error) {
        console.error("Error grave en el servidor:", error);
      }
    } else {
      console.log(" Ignorando evento que no es 'payment'. Tipo:", paymentInfo.type);
    }

    // Siempre responder rápido a Mercado Pago
    return res.status(200).send('OK');
  }

  res.status(405).send('Método no permitido');
}