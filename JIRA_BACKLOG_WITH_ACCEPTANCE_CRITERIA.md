# Gift Card Marketplace - JIRA Backlog with Acceptance Criteria

## Epic 1: Company Authentication & Authorization

### Story 1.1: Company Registration
**As a company admin, I want to register my company account so that I can access the gift card marketplace**

**Acceptance Criteria:**
- [ ] Given I am on the registration page, when I submit valid company details (company name, email, password, phone, tax ID), then my account is created successfully
- [ ] Given I submit the registration form, when the email already exists, then I see an error message "Email already registered"
- [ ] Given I create an account, when registration is successful, then I receive a verification email
- [ ] Given I receive a verification email, when I click the verification link, then my account is activated
- [ ] Given I try to log in, when my account is not verified, then I see "Please verify your email first"
- [ ] Given I enter company details, when any required field is missing, then I see appropriate validation errors
- [ ] Given I enter a password, when it doesn't meet security requirements (min 8 chars, 1 uppercase, 1 number, 1 special char), then I see password strength requirements
- [ ] Given I complete registration, when successful, then I am redirected to the login page with a success message

**Story Points:** 8

**Tasks:**
- Create company registration API endpoint
- Design company registration form UI
- Implement form validation
- Add email verification flow
- Create company profile database schema
- Write unit tests for registration

---

### Story 1.2: Company Login
**As a company user, I want to log in with my credentials so that I can access the platform**

**Acceptance Criteria:**
- [ ] Given I am on the login page, when I enter valid credentials, then I am logged in and redirected to the dashboard
- [ ] Given I enter credentials, when they are invalid, then I see "Invalid email or password"
- [ ] Given I check "Remember Me", when I close and reopen the browser, then I am still logged in
- [ ] Given I click "Forgot Password", when I enter my email, then I receive a password reset link
- [ ] Given I receive a reset link, when I click it and enter a new password, then my password is updated
- [ ] Given I attempt login, when I fail 5 times, then my account is temporarily locked for 15 minutes
- [ ] Given I log in successfully, when I receive a JWT token, then it expires after 24 hours
- [ ] Given I am logged in, when my token expires, then I am redirected to login with a "Session expired" message
- [ ] Given I log in, when successful, then my session is tracked in the database

**Story Points:** 8

**Tasks:**
- Create login API endpoint with JWT authentication
- Design login page UI
- Implement "Remember Me" functionality
- Add "Forgot Password" flow
- Implement session management
- Add rate limiting for login attempts
- Write authentication middleware
- Write unit and integration tests

---

### Story 1.3: Role-Based Access Control
**As a company admin, I want to manage user roles and permissions within my organization**

**Acceptance Criteria:**
- [ ] Given I am a company admin, when I access user management, then I can view all users in my organization
- [ ] Given I am a company admin, when I invite a new user, then they receive an invitation email
- [ ] Given I invite a user, when I assign them a role (Admin, Manager, User), then they have appropriate permissions
- [ ] Given I am an Admin, when I try to access admin features, then I have full access
- [ ] Given I am a Manager, when I try to access order history and placement, then I have access
- [ ] Given I am a User, when I try to access user management, then I see "Access denied"
- [ ] Given I am a company admin, when I deactivate a user, then they cannot log in
- [ ] Given a user is deactivated, when they try to log in, then they see "Account has been deactivated"

**Story Points:** 8

**Tasks:**
- Design role/permission database schema
- Create role management API endpoints
- Implement authorization middleware
- Define permission levels (Admin, Manager, User)
- Write authorization tests

---

## Epic 2: Gift Card Marketplace

### Story 2.1: Resal API Integration
**As a developer, I want to integrate with Resal API so that we can fetch available gift cards**

**Acceptance Criteria:**
- [ ] Given the system starts, when it connects to Resal API, then authentication is successful
- [ ] Given I request gift cards, when the API call succeeds, then I receive a list of available gift cards
- [ ] Given I request gift cards, when Resal API is down, then the system retries 3 times with exponential backoff
- [ ] Given I fetch gift cards, when data is received, then it is transformed to our internal format
- [ ] Given gift card data is fetched, when it's less than 1 hour old, then cached data is returned
- [ ] Given the Resal API returns an error, when it occurs, then it is logged and a user-friendly message is shown
- [ ] Given I request gift card details, when the API call succeeds, then all relevant fields are mapped correctly (id, name, brand, price, image, description, terms)

**Story Points:** 13

**Tasks:**
- Research Resal API documentation
- Create Resal API service/client
- Implement authentication with Resal API
- Create data transformation layer for Resal responses
- Implement error handling and retry logic
- Add API response caching strategy
- Write integration tests

---

### Story 2.2: Gift Card Listing Page
**As a company user, I want to view available gift cards so that I can browse options**

**Acceptance Criteria:**
- [ ] Given I navigate to the marketplace, when the page loads, then I see a grid of gift cards
- [ ] Given gift cards are displayed, when I view a card, then I see: image, brand name, price, and "Add to Cart" button
- [ ] Given there are more than 20 gift cards, when I scroll to the bottom, then the next page loads automatically (infinite scroll) OR I see pagination controls
- [ ] Given the page is loading, when gift cards are being fetched, then I see a loading skeleton/spinner
- [ ] Given the API fails, when an error occurs, then I see "Unable to load gift cards. Please try again."
- [ ] Given I am on mobile, when I view the listing, then the layout is responsive and cards stack vertically
- [ ] Given there are no gift cards available, when the page loads, then I see "No gift cards available at the moment"

**Story Points:** 8

**Tasks:**
- Design gift card listing page UI
- Create gift card listing API endpoint
- Implement pagination
- Add loading states and error handling
- Display card details (image, price, brand, etc.)
- Optimize for mobile responsiveness
- Write component tests

---

### Story 2.3: Gift Card Filtering
**As a company user, I want to filter gift cards by category, price range, and brand**

**Acceptance Criteria:**
- [ ] Given I am on the marketplace, when I click "Filters", then a filter panel opens
- [ ] Given the filter panel is open, when I select a category, then only gift cards in that category are shown
- [ ] Given I set a price range (min-max), when I apply it, then only gift cards within that range are shown
- [ ] Given I select multiple brands, when I apply the filter, then only gift cards from those brands are shown
- [ ] Given I apply multiple filters, when I click "Clear All", then all filters are removed and all gift cards are shown
- [ ] Given I apply filters, when I navigate away and come back, then my filters are preserved (stored in URL params)
- [ ] Given I apply filters, when no results match, then I see "No gift cards match your criteria"
- [ ] Given I select filters, when I apply them, then the gift card count updates in real-time

**Story Points:** 8

**Tasks:**
- Design filter UI component
- Implement category filter
- Implement price range filter
- Implement brand/merchant filter
- Add "Clear All Filters" functionality
- Update API to support filter parameters
- Add filter state persistence
- Write filter tests

---

### Story 2.4: Gift Card Search
**As a company user, I want to search for specific gift cards by name or brand**

**Acceptance Criteria:**
- [ ] Given I am on the marketplace, when I type in the search box, then results update after I stop typing for 500ms (debounced)
- [ ] Given I type a search term, when matches are found, then only matching gift cards are displayed
- [ ] Given I search for a brand name, when I type "Ama", then I see suggestions like "Amazon"
- [ ] Given I search for a term, when the search term is highlighted, then it appears in bold in the results
- [ ] Given I search for a term, when no results match, then I see "No results found for '[search term]'"
- [ ] Given I type a search, when I clear it, then all gift cards are shown again
- [ ] Given I have filters applied, when I search, then search works within the filtered results

**Story Points:** 5

**Tasks:**
- Design search bar UI
- Implement search API endpoint
- Add autocomplete/suggestions
- Implement debouncing for search input
- Add search result highlighting
- Handle empty search results
- Write search tests

---

### Story 2.5: Gift Card Details View
**As a company user, I want to view detailed information about a gift card**

**Acceptance Criteria:**
- [ ] Given I click on a gift card, when the detail view opens, then I see: full description, terms & conditions, redemption instructions, pricing options
- [ ] Given I view gift card details, when the card is out of stock, then the "Add to Cart" button is disabled with "Out of Stock" label
- [ ] Given I view details, when I click "Add to Cart", then the item is added and I see a success message
- [ ] Given I am on the detail view, when I click "Close" or outside the modal, then it closes and I return to the listing
- [ ] Given I view details, when there are multiple denominations available, then I can select the amount I want

**Story Points:** 5

**Tasks:**
- Design gift card detail page/modal
- Create gift card detail API endpoint
- Display terms and conditions
- Show availability status
- Add "Add to Cart" button
- Write detail view tests

---

## Epic 3: Shopping Cart Management

### Story 3.1: Add to Cart Functionality
**As a company user, I want to add gift cards to my cart so that I can purchase multiple items**

**Acceptance Criteria:**
- [ ] Given I am viewing a gift card, when I click "Add to Cart", then the item is added to my cart
- [ ] Given I add an item to cart, when successful, then I see a success notification "Added to cart"
- [ ] Given I add an item, when it's already in my cart, then the quantity increases by 1
- [ ] Given I add an item, when I select a quantity, then that quantity is added to the cart
- [ ] Given I add an item to cart, when successful, then the cart icon shows the updated item count
- [ ] Given I am not logged in, when I add items to cart, then they are saved in local storage
- [ ] Given I log in, when I had items in local storage, then they are merged with my server-side cart

**Story Points:** 8

**Tasks:**
- Create cart database schema
- Create "Add to Cart" API endpoint
- Implement cart state management (frontend)
- Add quantity selector
- Show cart item count indicator
- Add success/error notifications
- Write cart tests

---

### Story 3.2: View Shopping Cart
**As a company user, I want to view my cart contents so that I can review my selections**

**Acceptance Criteria:**
- [ ] Given I click the cart icon, when the cart page loads, then I see all items I added
- [ ] Given I view my cart, when it has items, then I see: item image, name, price, quantity, subtotal for each item
- [ ] Given I view my cart, when it has items, then I see the total cost at the bottom
- [ ] Given my cart is empty, when I view it, then I see "Your cart is empty" with a "Browse Gift Cards" button
- [ ] Given I view my cart, when items are shown, then I see "Proceed to Checkout" button
- [ ] Given I have cart items, when I close the browser and reopen, then my cart items persist

**Story Points:** 5

**Tasks:**
- Design shopping cart page UI
- Create "Get Cart" API endpoint
- Display cart items with details
- Show subtotal and total
- Add empty cart state
- Implement cart session persistence
- Write cart display tests

---

### Story 3.3: Update Cart Items
**As a company user, I want to modify quantities or remove items from my cart**

**Acceptance Criteria:**
- [ ] Given I view my cart, when I increase quantity, then the subtotal and total update immediately
- [ ] Given I view my cart, when I decrease quantity to 0, then the item is removed
- [ ] Given I view my cart, when I click "Remove" on an item, then it is removed with a confirmation
- [ ] Given I view my cart, when I click "Clear Cart", then I see a confirmation dialog
- [ ] Given I confirm clear cart, when confirmed, then all items are removed
- [ ] Given I update quantities, when I navigate away and return, then the quantities are preserved
- [ ] Given I change quantities, when I update, then the cart icon count updates

**Story Points:** 5

**Tasks:**
- Create "Update Cart" API endpoint
- Create "Remove from Cart" API endpoint
- Implement quantity increment/decrement UI
- Add "Remove Item" button
- Add "Clear Cart" functionality
- Update totals dynamically
- Write update cart tests

---

### Story 3.4: Cart Validation
**As a system, I want to validate cart contents before checkout**

**Acceptance Criteria:**
- [ ] Given I proceed to checkout, when an item is out of stock, then I see "Item [name] is no longer available"
- [ ] Given I proceed to checkout, when a price has changed, then I see "Price for [name] has changed from X to Y"
- [ ] Given I proceed to checkout, when validation fails, then the "Proceed" button is disabled until I resolve issues
- [ ] Given my cart has issues, when I view them, then invalid items are highlighted with error messages
- [ ] Given I have more than 100 items in cart, when I add more, then I see "Cart limit reached (100 items max)"

**Story Points:** 5

**Tasks:**
- Implement stock/availability validation
- Check for price changes
- Validate cart item limits
- Add validation error messages
- Write validation tests

---

## Epic 4: Bulk Order Processing via Excel

### Story 4.1: Excel Template Design
**As a company user, I want to download an Excel template so that I can properly format recipient data**

**Acceptance Criteria:**
- [ ] Given I am on the checkout page, when I click "Download Template", then an Excel file is downloaded
- [ ] Given I open the template, when I view it, then I see columns: Recipient Name, Recipient Email, Gift Card Name, Amount/Denomination, Custom Message (optional)
- [ ] Given I open the template, when I view it, then I see instructions in the first row or a separate sheet
- [ ] Given I view instructions, when I read them, then I understand the format requirements and validation rules
- [ ] Given the template is downloaded, when opened, then it has example data in the first row (commented out or on a separate sheet)

**Story Points:** 3

**Tasks:**
- Design Excel template structure
- Create template generation endpoint
- Add template download button in UI
- Include instructions/validation rules in template
- Write template generation tests

---

### Story 4.2: Excel File Upload
**As a company user, I want to upload an Excel file with recipient details**

**Acceptance Criteria:**
- [ ] Given I am on the checkout page, when I click "Upload Recipients", then a file picker opens
- [ ] Given I select a file, when it's larger than 10MB, then I see "File too large. Maximum size is 10MB"
- [ ] Given I select a file, when it's not .xlsx or .xls, then I see "Invalid file format. Please upload .xlsx or .xls"
- [ ] Given I drag and drop a file, when it's a valid Excel file, then it uploads successfully
- [ ] Given I upload a file, when uploading, then I see a progress bar
- [ ] Given upload is successful, when complete, then I see "File uploaded successfully" and proceed to validation

**Story Points:** 5

**Tasks:**
- Design file upload UI component
- Create file upload API endpoint
- Implement file size validation
- Support .xlsx and .xls formats
- Add drag-and-drop functionality
- Show upload progress indicator
- Write file upload tests

---

### Story 4.3: Excel Data Parsing & Validation
**As a system, I want to parse and validate the uploaded Excel file**

**Acceptance Criteria:**
- [ ] Given a file is uploaded, when it's parsed, then all rows with data are extracted
- [ ] Given the file is parsed, when required columns are missing, then I see "Missing required columns: [list]"
- [ ] Given I upload data, when an email is invalid, then I see "Row [X]: Invalid email format"
- [ ] Given I upload data, when there are duplicate emails, then I see "Duplicate emails found: [list]"
- [ ] Given I upload data, when a gift card name doesn't match my cart, then I see "Row [X]: Gift card '[name]' not found in cart"
- [ ] Given I upload data, when amounts don't match available denominations, then I see "Row [X]: Invalid amount for [gift card name]"
- [ ] Given validation finds errors, when complete, then I see a detailed error report with row numbers
- [ ] Given the file is valid, when parsing is complete, then I see "X recipients parsed successfully"
- [ ] Given the file has more than 1000 rows, when uploaded, then I see "Maximum 1000 recipients per order"

**Story Points:** 13

**Tasks:**
- Implement Excel parsing library integration
- Validate required columns exist
- Validate email format for recipients
- Check for duplicate entries
- Validate gift card assignments against cart
- Create detailed validation error report
- Handle malformed files gracefully
- Write parsing and validation tests

---

### Story 4.4: Assignment Preview
**As a company user, I want to preview the gift card assignments before finalizing**

**Acceptance Criteria:**
- [ ] Given validation succeeds, when I view the preview, then I see a table with all parsed recipients
- [ ] Given I view the preview, when I see the data, then I can see: recipient name, email, gift card, amount, custom message
- [ ] Given I view the preview, when there are validation warnings (non-critical), then they are highlighted in yellow
- [ ] Given I view the preview, when I click "Edit", then I can modify individual rows
- [ ] Given I view the preview, when I click "Re-upload", then I can upload a new file
- [ ] Given I view the preview, when I scroll to the bottom, then I see a summary: Total recipients, Total cost, Total gift cards
- [ ] Given I review the data, when I click "Proceed to Order", then I move to the order finalization step

**Story Points:** 8

**Tasks:**
- Design assignment preview UI
- Display parsed data in table format
- Show validation errors inline
- Allow corrections before proceeding
- Show summary (total recipients, total cost)
- Add "Edit" and "Re-upload" options
- Write preview tests

---

## Epic 5: Order Management

### Story 5.1: Order Review Page
**As a company user, I want to review my order details before placing it**

**Acceptance Criteria:**
- [ ] Given I proceed from preview, when the order review page loads, then I see: cart items summary, recipient count, total cost breakdown
- [ ] Given I view the order review, when I see the cost breakdown, then it shows: Subtotal, Tax (if applicable), Service Fee (if applicable), Total
- [ ] Given I view the summary, when I click "Edit Cart", then I return to the cart page
- [ ] Given I view the summary, when I click "Edit Recipients", then I return to the upload/preview page
- [ ] Given I view the order, when I scroll down, then I see terms and conditions with a checkbox "I agree to the terms"
- [ ] Given I haven't agreed to terms, when I try to place order, then the button is disabled
- [ ] Given I agree to terms, when I click "Place Order", then the order is submitted

**Story Points:** 5

**Tasks:**
- Design order review page UI
- Display order summary (items, quantities, recipients)
- Show total cost breakdown
- Display recipient count
- Add "Edit Cart" and "Edit Recipients" links
- Write review page tests

---

### Story 5.2: Order Placement
**As a company user, I want to place my order so that gift cards can be processed**

**Acceptance Criteria:**
- [ ] Given I click "Place Order", when the request is sent, then I see a loading indicator
- [ ] Given the order is successful, when created, then I receive a unique order reference number (e.g., ORD-2025-001234)
- [ ] Given the order is successful, when created, then I am redirected to an order confirmation page
- [ ] Given I view the confirmation page, when loaded, then I see: order reference, status, estimated completion time
- [ ] Given the order fails, when an error occurs, then I see the specific error message and can retry
- [ ] Given the order is placed, when created, then the cart is cleared
- [ ] Given the order is placed, when created, then an order confirmation email is sent to me

**Story Points:** 8

**Tasks:**
- Create "Place Order" API endpoint
- Design order database schema
- Implement order creation logic
- Generate unique order reference number
- Process payment/billing integration (if applicable)
- Add order confirmation page
- Write order placement tests

---

### Story 5.3: Order Processing with Resal
**As a system, I want to purchase gift cards from Resal API for the order**

**Acceptance Criteria:**
- [ ] Given an order is placed, when processing starts, then the order status is "Processing"
- [ ] Given the order is processing, when gift cards are purchased from Resal, then each purchase is logged
- [ ] Given a purchase succeeds, when the code is received, then it's stored securely (encrypted)
- [ ] Given a purchase fails, when it happens, then the system retries up to 3 times
- [ ] Given some purchases fail after retries, when this occurs, then the order is marked "Partially Failed" with details
- [ ] Given all purchases succeed, when complete, then the order status is "Completed"
- [ ] Given all purchases fail, when complete, then the order status is "Failed" and a refund is initiated (if payment was processed)
- [ ] Given the order is processed, when complete, then the email distribution job is triggered

**Story Points:** 13

**Tasks:**
- Create Resal purchase API integration
- Implement bulk purchase logic
- Handle partial failures gracefully
- Store gift card codes securely
- Implement retry mechanism for failed purchases
- Add order status tracking (pending, processing, completed, failed)
- Write processing tests

---

### Story 5.4: Order History
**As a company user, I want to view my past orders and their status**

**Acceptance Criteria:**
- [ ] Given I navigate to "My Orders", when the page loads, then I see a list of all my orders
- [ ] Given I view my orders, when displayed, then each shows: order reference, date, status, total cost, recipient count
- [ ] Given I view my orders, when I click on an order, then I see the full order details
- [ ] Given I view the order list, when I filter by date range, then only orders in that range are shown
- [ ] Given I view the order list, when I filter by status (Completed, Processing, Failed), then only matching orders are shown
- [ ] Given I have no orders, when I view the page, then I see "No orders yet" with a link to the marketplace
- [ ] Given I view an order, when I click "Download Receipt", then a PDF receipt is generated

**Story Points:** 8

**Tasks:**
- Design order history page UI
- Create "Get Orders" API endpoint
- Implement order filtering (date range, status)
- Add order detail view
- Show order status
- Add "Download Receipt" functionality
- Write order history tests

---

### Story 5.5: Order Details & Tracking
**As a company user, I want to view detailed information about a specific order**

**Acceptance Criteria:**
- [ ] Given I click on an order, when the detail page loads, then I see: order reference, date/time, status, cart items, recipient list
- [ ] Given I view order details, when I see the status, then I see a timeline: Order Placed → Processing → Completed
- [ ] Given I view the recipient list, when displayed, then I see: name, email, gift card, delivery status (Sent, Delivered, Failed, Opened)
- [ ] Given an email failed, when I see it, then I can click "Resend Email" for that recipient
- [ ] Given I click "Resend Email", when successful, then I see "Email resent successfully"
- [ ] Given I view details, when I click "Download Codes", then I get a CSV with all codes (for backup purposes)

**Story Points:** 8

**Tasks:**
- Design order detail page UI
- Create "Get Order by ID" API endpoint
- Display order status timeline
- Show recipient list and delivery status
- Add "Resend Email" option for failed deliveries
- Write order detail tests

---

## Epic 6: Email Distribution System

### Story 6.1: Email Template Design
**As a company, I want professional email templates for gift card delivery**

**Acceptance Criteria:**
- [ ] Given an email is sent, when a recipient receives it, then they see: company logo, personalized greeting, gift card details, redemption code, redemption instructions
- [ ] Given the email is viewed, when on mobile, then it displays correctly (responsive design)
- [ ] Given the email is viewed, when on desktop, then it displays correctly with proper formatting
- [ ] Given a recipient views the email, when they see the code, then it's displayed prominently (large font, highlighted)
- [ ] Given the email includes a custom message, when present, then it's displayed in a dedicated section
- [ ] Given the email is sent, when it includes a gift card, then it shows the brand logo and description

**Story Points:** 5

**Tasks:**
- Design email template HTML
- Include company branding
- Add gift card details and code prominently
- Include redemption instructions
- Make template mobile-responsive
- Create multiple template variations
- Write template rendering tests

---

### Story 6.2: Email Service Integration
**As a developer, I want to integrate an email service provider**

**Acceptance Criteria:**
- [ ] Given the system sends an email, when the service is called, then it successfully delivers via the email provider (SendGrid/AWS SES)
- [ ] Given emails are sent, when rate limits exist, then the system respects them (e.g., 100 emails per second max)
- [ ] Given an email is sent, when it's delivered, then the delivery status is tracked
- [ ] Given an email is opened, when the recipient opens it, then an open event is recorded
- [ ] Given an email link is clicked, when a recipient clicks it, then a click event is recorded
- [ ] Given the email service fails, when an error occurs, then it's logged with full details for debugging

**Story Points:** 8

**Tasks:**
- Choose email service (SendGrid, AWS SES, etc.)
- Set up email service account and credentials
- Create email service wrapper/client
- Implement email queue system
- Add rate limiting to prevent spam
- Implement email tracking (opens, clicks)
- Write email service tests

---

### Story 6.3: Bulk Email Sending
**As a system, I want to send gift card codes to all recipients in an order**

**Acceptance Criteria:**
- [ ] Given an order is completed, when processing finishes, then emails are queued for all recipients
- [ ] Given emails are queued, when sending starts, then they are sent in batches (e.g., 50 per batch)
- [ ] Given a recipient is in the list, when their email is sent, then they receive their specific gift card code
- [ ] Given an email fails to send, when it fails, then the system retries up to 3 times
- [ ] Given an email fails after retries, when this happens, then it's marked as "Failed" with the error reason
- [ ] Given all emails are processed, when complete, then the order status is updated to show email completion percentage
- [ ] Given emails are sending, when I view the order, then I see real-time progress (e.g., "50/100 emails sent")

**Story Points:** 13

**Tasks:**
- Create email sending job/worker
- Implement batch email processing
- Map gift card codes to recipients from Excel data
- Handle email delivery failures
- Implement retry logic for failed emails
- Log email delivery status
- Update order status based on email completion
- Write bulk sending tests

---

### Story 6.4: Email Delivery Monitoring
**As a company user, I want to track email delivery status for my orders**

**Acceptance Criteria:**
- [ ] Given I view an order, when emails have been sent, then I see a delivery dashboard with metrics
- [ ] Given I view the dashboard, when displayed, then I see: Total Sent, Delivered, Failed, Opened, Clicked
- [ ] Given emails failed, when I view them, then I see a list of failed emails with reasons
- [ ] Given I see failed emails, when I click "Resend Failed Emails", then all failed emails are queued for resending
- [ ] Given I view individual recipients, when I click on one, then I see their email history: sent time, delivered time, opened time
- [ ] Given I view email logs, when displayed, then I can filter by status (Sent, Delivered, Failed, Opened)

**Story Points:** 8

**Tasks:**
- Design email status dashboard UI
- Create email status tracking API
- Display delivery metrics (sent, delivered, failed, opened)
- Add "Resend Failed Emails" functionality
- Show individual recipient email status
- Add email logs/history
- Write monitoring tests

---

### Story 6.5: Email Customization
**As a company admin, I want to customize email content and branding**

**Acceptance Criteria:**
- [ ] Given I am on the email settings page, when I upload a logo, then it appears in all future emails
- [ ] Given I set a custom sender name, when emails are sent, then they show "From: [Custom Name]"
- [ ] Given I customize the email subject, when I enter a subject with variables (e.g., {recipient_name}, {gift_card_name}), then they are replaced correctly in sent emails
- [ ] Given I customize the email body, when I add a custom message, then it appears in all emails
- [ ] Given I make changes, when I click "Preview", then I see how the email will look
- [ ] Given I create a custom template, when I save it, then I can select it for future orders
- [ ] Given I have multiple templates, when placing an order, then I can choose which template to use

**Story Points:** 8

**Tasks:**
- Design email customization UI
- Allow custom sender name
- Allow custom email subject
- Allow custom message body
- Preview email before sending
- Save email templates
- Write customization tests

---

---

# SPRINT PLAN

## Sprint Overview
- **Sprint Duration:** 2 weeks
- **Total Sprints:** 6 sprints (12 weeks / ~3 months)
- **Team Velocity Assumption:** 40 story points per sprint (adjust based on team size)

---

## Sprint 1 (Weeks 1-2): Foundation & Authentication
**Goal:** Set up project infrastructure and implement core authentication

### Stories:
1. **Story 1.2: Company Login** - 8 points
2. **Story 1.3: Role-Based Access Control** - 8 points
3. **Story 2.1: Resal API Integration** - 13 points

### Technical Tasks:
- Set up development environment (database, backend, frontend)
- Configure CI/CD pipeline
- Set up project structure and coding standards
- Initialize database with schema

**Total Story Points:** 29

### Sprint Goals:
- Companies can log in and access the platform
- Basic role-based permissions are enforced
- Resal API connection is established and working

### Definition of Done:
- All acceptance criteria met
- Unit tests written and passing (80% coverage minimum)
- Code reviewed and merged
- Deployed to staging environment

---

## Sprint 2 (Weeks 3-4): Marketplace Foundation
**Goal:** Build the core marketplace browsing experience

### Stories:
1. **Story 2.2: Gift Card Listing Page** - 8 points
2. **Story 2.3: Gift Card Filtering** - 8 points
3. **Story 2.4: Gift Card Search** - 5 points
4. **Story 2.5: Gift Card Details View** - 5 points
5. **Story 3.1: Add to Cart Functionality** - 8 points

**Total Story Points:** 34

### Sprint Goals:
- Users can browse, filter, and search gift cards
- Users can view gift card details
- Users can add gift cards to cart

### Definition of Done:
- All acceptance criteria met
- Integration tests for Resal API
- UI/UX approved by stakeholders
- Performance: Page loads in < 2 seconds

---

## Sprint 3 (Weeks 5-6): Shopping Cart & Excel Upload
**Goal:** Complete shopping cart functionality and implement Excel upload

### Stories:
1. **Story 3.2: View Shopping Cart** - 5 points
2. **Story 3.3: Update Cart Items** - 5 points
3. **Story 3.4: Cart Validation** - 5 points
4. **Story 4.1: Excel Template Design** - 3 points
5. **Story 4.2: Excel File Upload** - 5 points
6. **Story 4.3: Excel Data Parsing & Validation** - 13 points

**Total Story Points:** 36

### Sprint Goals:
- Full shopping cart CRUD operations
- Excel template available for download
- Excel file upload and validation working

### Definition of Done:
- All acceptance criteria met
- Excel parsing handles edge cases (empty rows, special characters)
- Comprehensive validation error messages
- Cart state persists across sessions

---

## Sprint 4 (Weeks 7-8): Order Processing
**Goal:** Implement order placement and Resal integration

### Stories:
1. **Story 4.4: Assignment Preview** - 8 points
2. **Story 5.1: Order Review Page** - 5 points
3. **Story 5.2: Order Placement** - 8 points
4. **Story 5.3: Order Processing with Resal** - 13 points

**Total Story Points:** 34

### Sprint Goals:
- Users can review assignments before ordering
- Orders can be placed successfully
- Gift cards are purchased from Resal API
- Order status tracking is functional

### Definition of Done:
- All acceptance criteria met
- Secure storage of gift card codes (encryption)
- Error handling for partial failures
- Transaction rollback on critical failures
- Load testing for bulk orders (up to 1000 recipients)

---

## Sprint 5 (Weeks 9-10): Email Distribution System
**Goal:** Build the email sending and tracking system

### Stories:
1. **Story 6.1: Email Template Design** - 5 points
2. **Story 6.2: Email Service Integration** - 8 points
3. **Story 6.3: Bulk Email Sending** - 13 points
4. **Story 5.4: Order History** - 8 points

**Total Story Points:** 34

### Sprint Goals:
- Professional email templates created
- Email service integrated (SendGrid/AWS SES)
- Bulk email sending operational
- Users can view order history

### Definition of Done:
- All acceptance criteria met
- Email templates tested on multiple clients (Gmail, Outlook, Apple Mail)
- Email queue system handles failures gracefully
- Rate limiting implemented
- Email tracking (opens, clicks) functional

---

## Sprint 6 (Weeks 11-12): Monitoring, Enhancement & Polish
**Goal:** Add monitoring, complete remaining features, and polish the application

### Stories:
1. **Story 5.5: Order Details & Tracking** - 8 points
2. **Story 6.4: Email Delivery Monitoring** - 8 points
3. **Story 1.1: Company Registration** - 8 points
4. **Bug Fixes & Polish** - 8 points
5. **Documentation** - 3 points

**Total Story Points:** 35

### Technical Tasks:
- Set up application monitoring (Sentry, CloudWatch)
- Complete API documentation (Swagger)
- User acceptance testing (UAT)
- Performance optimization
- Security audit
- Deployment to production

### Sprint Goals:
- Complete email delivery monitoring dashboard
- Company registration available
- All critical bugs fixed
- Application ready for production

### Definition of Done:
- All acceptance criteria met
- Full E2E test suite passing
- Documentation complete (API docs, user manual)
- Security review completed
- Production deployment successful
- Stakeholder sign-off

---

## Post-Launch (Optional - Sprint 7+)
### Stories to Consider:
- **Story 6.5: Email Customization** - 8 points
- Advanced reporting and analytics
- Multi-language support
- Mobile app (if needed)
- Integration with accounting systems
- Bulk order templates (save frequently used recipient lists)

---

## Risk Mitigation Plan

### High-Risk Items:
1. **Resal API Integration (Story 2.1, 5.3)**
   - **Risk:** API changes, downtime, or unexpected behavior
   - **Mitigation:** Early integration in Sprint 1, comprehensive error handling, fallback mechanisms

2. **Bulk Email Sending (Story 6.3)**
   - **Risk:** Email deliverability issues, rate limiting, spam filters
   - **Mitigation:** Use reputable email service, implement email warm-up, SPF/DKIM configuration

3. **Excel Parsing (Story 4.3)**
   - **Risk:** Complex validation, edge cases, large file handling
   - **Mitigation:** Extensive testing with various file formats, clear error messages, file size limits

4. **Order Processing (Story 5.3)**
   - **Risk:** Partial failures, data inconsistency, transaction management
   - **Mitigation:** Implement idempotency, proper transaction boundaries, comprehensive logging

### Dependencies:
- **Resal API Access:** Required before Sprint 1
- **Email Service Account:** Required before Sprint 5
- **Database Infrastructure:** Required before Sprint 1

---

## Key Metrics to Track

### During Development:
- Velocity per sprint
- Bug count (critical vs non-critical)
- Code coverage percentage
- API response times
- Build success rate

### Post-Launch:
- Order completion rate
- Email delivery rate
- Average order processing time
- User satisfaction (NPS)
- System uptime

---

## Daily Standup Structure
**Three Questions:**
1. What did I complete yesterday?
2. What will I work on today?
3. Are there any blockers?

**Focus Areas:**
- Sprint goal progress
- Dependency management
- Risk identification

---

## Sprint Ceremonies

### Sprint Planning (Day 1 of Sprint)
- Review and refine stories
- Estimate effort
- Commit to sprint goal
- Break down stories into tasks

### Daily Standups (Every Day - 15 mins)
- Sync on progress
- Identify blockers
- Adjust plan if needed

### Sprint Review (Last Day of Sprint)
- Demo completed features
- Gather stakeholder feedback
- Accept or reject stories

### Sprint Retrospective (Last Day of Sprint)
- What went well?
- What could be improved?
- Action items for next sprint

---

## Success Criteria for Q1 Delivery

### Functional Requirements:
- [ ] Companies can log in and manage users
- [ ] Gift cards can be browsed, filtered, and searched
- [ ] Shopping cart fully functional
- [ ] Excel upload and validation working
- [ ] Orders can be placed and processed
- [ ] Emails sent to recipients with gift card codes
- [ ] Order history and tracking available

### Non-Functional Requirements:
- [ ] 99% uptime
- [ ] Page load times < 2 seconds
- [ ] Handle orders with up to 1000 recipients
- [ ] Email delivery rate > 98%
- [ ] All critical security vulnerabilities addressed
- [ ] API documentation complete

### Business Goals:
- [ ] Successful UAT with 3-5 pilot companies
- [ ] Process at least 100 gift cards in testing
- [ ] Positive feedback from stakeholders
- [ ] Production-ready deployment

---

This sprint plan provides a clear roadmap for the next 12 weeks. Adjust story points and sprint allocations based on your team's actual velocity after Sprint 1-2.
