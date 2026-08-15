"""Test email verification flow."""
import os
# Read the SendGrid key from the environment — never hardcode secrets in source.
os.environ.setdefault('SENDGRID_API_KEY', os.getenv('SENDGRID_API_KEY', ''))
os.environ['EMAIL_FROM'] = 'support@taskteddy.com'
os.environ['FRONTEND_URL'] = 'http://localhost:3000'

from utils.email import send_verification_email, send_welcome_email

# Test verification email
print('1. Sending verification email...')
result = send_verification_email('ankit.sharma@taskteddy.com', 'Ankit', 'test-token-abc123')
print(f'   Result: {result}')

# Test welcome email
print('2. Sending welcome email...')
result2 = send_welcome_email('ankit.sharma@taskteddy.com', 'Ankit')
print(f'   Result: {result2}')

print('3. Done! Check your inbox.')