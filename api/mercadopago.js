import { MercadoPagoConfig, Preference } from 'mercadopago';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Método no permitido' });
  }

  try {
    // 1. Extraemos los datos (ahora recibimos token_ciudadano de Flutter)
    const { titulo, monto, reciboId, token_ciudadano } = req.body;

    if (!monto) {
      return res.status(400).json({ error: 'Falta el monto a pagar' });
    }

    const client = new MercadoPagoConfig({ 
      accessToken: process.env.MERCADOPAGO_ACCESS_TOKEN 
    });

    const preference = new Preference(client);
    
    // 2. Creamos la "Preferencia" con esteroides
    const response = await preference.create({
      body: {
        items: [
          {
            id: reciboId || '000',
            title: titulo || 'Pago de Servicio de Agua',
            quantity: 1,
            unit_price: Number(monto),
            currency_id: 'MXN'
          }
        ],
        // Esto le dice a Mercado Pago a qué archivo llamar para avisar del pago
        notification_url: "https://pozo-cazadero.vercel.app/api/webhook",
        
        // Estos datos NO los ve el usuario, pero nos los devuelve el Webhook
        metadata: {
          recibo_id: reciboId,
          token_ciudadano: token_ciudadano 
        },

        back_urls: {
          success: "https://pozo-cazadero.vercel.app",
          failure: "https://pozo-cazadero.vercel.app",
          pending: "https://pozo-cazadero.vercel.app"
        },
        auto_return: "approved"
      }
    });

    return res.status(200).json({ 
      url: response.init_point 
    });

  } catch (error) {
    console.error('Error al generar Mercado Pago:', error);
    return res.status(500).json({ error: 'Error interno del servidor' });
  }
}