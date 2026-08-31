const store = require('../store/dataStore');

/**
 * Service to dispatch onboarding and account notification emails
 */
class EmailService {
  /**
   * Send Merchant Onboarding Acceptance Email with Demo/Initial Login ID & Password
   */
  static async sendMerchantApprovalEmail({
    toEmail,
    recipientName,
    storeName,
    loginId,
    temporaryPassword,
    workingHours,
    address,
  }) {
    const emailPayload = {
      id: `EMAIL-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      to: toEmail,
      subject: `🎉 Your Store "${storeName}" is Approved! Merchant Login Credentials & Access Details`,
      type: 'MERCHANT_APPROVAL_ONBOARDING',
      timestamp: new Date().toISOString(),
      content: {
        recipientName,
        storeName,
        loginId,
        temporaryPassword,
        workingHours,
        address,
        loginPortalUrl: 'https://app.herdoor.com/login',
        instructions: [
          'Open the HerDoor mobile app or web portal.',
          'Select the "Merchant" login role.',
          `Enter your Login ID: ${loginId}`,
          `Enter your Demo/Initial Password: ${temporaryPassword}`,
          'Once logged in, customize your store opening status, inventory, and grinding settings.'
        ]
      },
      status: 'SENT'
    };

    if (!store.sentEmails) {
      store.sentEmails = [];
    }
    store.sentEmails.push(emailPayload);

    console.log(`\n======================================================`);
    console.log(`📧 [EMAIL SERVICE] Onboarding Email Sent to ${toEmail}`);
    console.log(`Subject: ${emailPayload.subject}`);
    console.log(`Store Name: ${storeName}`);
    console.log(`Demo / Login ID: ${loginId}`);
    console.log(`Demo / Password: ${temporaryPassword}`);
    console.log(`======================================================\n`);

    return emailPayload;
  }
}

module.exports = EmailService;
