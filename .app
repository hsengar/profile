function doPost(e) {
  try {
    // Parse the incoming data
    var data = JSON.parse(e.postData.contents);
    
    // Verify reCAPTCHA v2
    var recaptchaResponse = verifyRecaptchaV2(data.recaptcha_response);
    
    // Check if reCAPTCHA verification passed
    if (!recaptchaResponse.success) {
      return ContentService
        .createTextOutput(JSON.stringify({
          success: false, 
          error: 'reCAPTCHA verification failed. Please complete the verification and try again.'
        }))
        .setMimeType(ContentService.MimeType.JSON)
        .setHeader("Access-Control-Allow-Origin", "*");
    }
    
    // If reCAPTCHA passed, save to sheet
    var sheet = SpreadsheetApp.getActiveSheet();
    
    // Append data to sheet
    sheet.appendRow([
      data.name,
      data.email,
      data.phone || '',
      data.service || '',
      data.budget || '',
      data.message,
      new Date(),
      'Verified' // reCAPTCHA status
    ]);
    
    // Optional: Send email notification
    try {
      GmailApp.sendEmail(
        'hengar11@gmail.com', // Replace with your email
        'New Website Inquiry (reCAPTCHA Verified)',
        `New verified inquiry from: ${data.name} (${data.email})
        
Service: ${data.service}
Budget: ${data.budget}
Phone: ${data.phone}
Message: ${data.message}

Status: reCAPTCHA v2 Verified ✅
Submitted: ${new Date()}
        `
      );
    } catch (emailError) {
      console.log('Email notification failed:', emailError);
    }
    
    return ContentService
  .createTextOutput(JSON.stringify({success: true}))
  .setMimeType(ContentService.MimeType.JSON)
  .setHeader("Access-Control-Allow-Origin", "*");
      
  } catch (error) {
    return ContentService
      .createTextOutput(JSON.stringify({success: false, error: error.toString()}))
      .setMimeType(ContentService.MimeType.JSON)
      .setHeader("Access-Control-Allow-Origin", "*");
  }
}

function verifyRecaptchaV2(recaptchaResponse) {
  var secretKey = '6LfZJXQrAAAAAOdktICX1B3E93r26wGPTLfx6q4U'; // Replace with your reCAPTCHA v2 secret key
  var verificationUrl = 'https://www.google.com/recaptcha/api/siteverify';
  
  var payload = {
    'secret': secretKey,
    'response': recaptchaResponse
  };
  
  var options = {
    'method': 'POST',
    'payload': payload
  };
  
  try {
    var response = UrlFetchApp.fetch(verificationUrl, options);
    var result = JSON.parse(response.getContentText());
    
    return {
      success: result.success,
      errorCodes: result['error-codes'] || []
    };
  } catch (error) {
    console.log('reCAPTCHA verification error:', error);
    return {
      success: false,
      errorCodes: ['verification-failed']
    };
  }
}