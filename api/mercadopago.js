import { MercadoPagoConfig, Preference } from 'mercadopago';

export default async function handler(req, res) {
  // Solo aceptamos peticiones POST
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Método no permitido' });
  }

  try {
    // 1. Extraemos los datos que manda tu app en Flutter
    const { titulo, monto, reciboId } = req.body;

    // 2. Validamos que vengan los datos
    if (!monto) {
      return res.status(400).json({ error: 'Falta el monto a pagar' });
    }

    // 3. Inicializamos Mercado Pago con tu Token
    // IMPORTANTE: El token lo configuraremos en Vercel, no lo pongas directo en el código por seguridad
    const client = new MercadoPagoConfig({ 
      accessToken: process.env.MP_ACCESS_TOKEN 
    });

    // 4. Creamos la "Preferencia" de pago (el cobro)
    const preference = new Preference(client);
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
        // Opcional: A dónde redirigir al usuario cuando termine
        back_urls: {
          success: "https://pozo-cazadero.vercel.app",
          failure: "https://pozo-cazadero.vercel.app",
          pending: "https://pozo-cazadero.vercel.app"
        },
        auto_return: "approved"
      }
    });

    // 5. Devolvemos el link de pago a Flutter
    // init_point es el link de Checkout Pro
    return res.status(200).json({ 
      url: response.init_point 
    });

  } catch (error) {
    console.error('Error al generar Mercado Pago:', error);
    return res.status(500).json({ error: 'Error interno del servidor' });
  }
}