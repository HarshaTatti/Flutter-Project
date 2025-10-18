# 🚀 HOW TO USE - Step by Step

## Right Now: 3 Simple Steps

### Step 1: Run Your App

```bash
flutter run -d chrome
```

Or if you want mobile:

```bash
flutter run -d android
# or
flutter run -d ios
```

---

### Step 2: Add Your Personal Data (First Time Only)

When the app starts, it will ask you to enter:

- **Name:** Your full name
- **Email:** Your email address
- **Phone:** Your phone number
- **Address:** Your home address
- **Interests:** Your hobbies/interests

💡 This data is stored **locally on your device only** - never sent anywhere!

---

### Step 3: Start Chatting!

Type these examples in the chat:

#### 1. Test Basic Queries

```
What is my name?
What's my email?
Tell me my phone number?
```

#### 2. Load a Document

- Click the **+** button at the bottom
- Select a `.txt` file (try the included `test_document.txt`)
- The AI will index it automatically

#### 3. Search Your Documents

```
search for privacy
find meeting notes
look for testing
```

#### 4. Try Natural Language

```
Hello!
What can you do?
How many documents do I have?
Show my documents
Goodbye!
```

---

## 📱 Quick Demo Script

Copy and paste these commands one by one to see the AI in action:

```
Hello!
```

_AI responds with a greeting_

```
What can you do?
```

_AI shows its capabilities_

```
What is my name?
```

_AI retrieves your name from local storage_

```
How many documents do I have?
```

_AI shows document count_

**Now load a document** (click + button, select `test_document.txt`)

```
search for privacy
```

_AI searches and ranks results with confidence scores_

```
find testing
```

_AI finds relevant content_

```
Thanks! Goodbye!
```

_AI says farewell_

---

## 🎯 What Each Feature Does

### 1. Personal Data Queries

**You ask:** "What's my email?"  
**AI does:**

- Classifies intent → "personal_query"
- Retrieves from local storage
- Responds naturally

### 2. Document Search

**You ask:** "search for budget"  
**AI does:**

- Extracts search term → "budget"
- Uses TF-IDF scoring
- Ranks with semantic similarity
- Generates smart summaries
- Shows confidence scores (92%, 76%, etc.)

### 3. Natural Conversations

**You ask:** "Hello!"  
**AI does:**

- Detects greeting intent
- Responds naturally
- Varies responses (not robotic)

---

## 🔍 Understanding Search Results

When you search, you'll see:

```
🔍 Found 2 relevant results for 'privacy':

1. **privacy_policy.txt** (92% match)
   This document outlines our privacy practices...

2. **meeting_notes.txt** (76% match)
   Discussed privacy concerns in meeting...

🤖 AI-powered local search • 🔒 100% private
```

**What the numbers mean:**

- **92% match** = AI confidence that this document is relevant
- Higher % = better match
- Based on: title relevance + content relevance + exact matches

---

## 📂 File Structure You Have

```
lib/
├── main.dart                    # Run this
├── services/
│   ├── chatbot_service.dart     # Main chatbot (with AI)
│   ├── smart_ai_service.dart    # AI engine (NEW!)
│   ├── document_service.dart    # Document search
│   └── local_data_service.dart  # Storage
```

---

## 🐛 Troubleshooting

### Problem: "I don't have any personal data stored yet"

**Solution:** The app needs initial setup. Enter your data when prompted.

### Problem: "You haven't loaded any documents yet"

**Solution:** Click the + button and select a .txt file

### Problem: Search not finding anything

**Solution:**

1. Make sure you loaded a document first
2. Try different keywords
3. Example: "search for [word that's in your document]"

### Problem: App won't start

**Solution:**

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d chrome
```

---

## 💡 Pro Tips

### 1. Better Search Results

Be specific:

- ✅ "search for budget meeting"
- ❌ "search for stuff"

### 2. Natural Language Works

You don't need exact commands:

- "find privacy" ✅
- "search for privacy" ✅
- "look for privacy information" ✅
- "anything about privacy?" ✅

### 3. Load Multiple Documents

- Load as many .txt files as you want
- The AI indexes all of them
- Searches across all documents

### 4. See the AI Confidence

- Higher % = AI is more confident
- 90%+ = Very relevant
- 70-89% = Probably relevant
- Below 70% = Might be tangentially related

---

## 📊 What's Happening Behind the Scenes

```
Your Query: "search for privacy"
           ↓
Step 1: AI Intent Classification (< 1ms)
        → Intent: "search_document" (90% confidence)
           ↓
Step 2: Entity Extraction (< 1ms)
        → search_term: "privacy"
           ↓
Step 3: TF-IDF Search (< 5ms)
        → Finds matching documents
           ↓
Step 4: AI Semantic Ranking (< 5ms)
        → Scores: doc1=92%, doc2=76%
           ↓
Step 5: Smart Summarization (< 5ms)
        → Extracts key sentences
           ↓
Result: Formatted response with confidence scores
```

**Total time: ~20ms (0.02 seconds)**

---

## 🎯 Try These Sample Queries

### Greetings

```
Hi
Hello there
Good morning
Hey!
```

### Help

```
What can you do?
Help me
Show me what you can do
```

### Personal Info

```
What is my name?
My email?
Tell me my phone number
What's my address?
What are my interests?
```

### Documents

```
How many documents?
List my documents
Show my documents
What documents do I have?
```

### Search (after loading documents)

```
search for privacy
find budget
look for meeting
search testing
find anything about security
```

---

## 🔒 Privacy Reminder

Everything happens **on your device**:

- ✅ No internet connection needed
- ✅ No data sent to servers
- ✅ No tracking or analytics
- ✅ 100% private
- ✅ Your data never leaves your device

The AI is pure Dart code running locally!

---

## 📚 More Information

- **Quick Reference:** `QUICK_START_AI.md`
- **AI Features:** `AI_FEATURES_README.md`
- **Technical Details:** `AI_IMPLEMENTATION_SUMMARY.md`
- **Full Guide:** `README.md`

---

## 🎉 That's It!

You're ready to use your AI-powered privacy chatbot!

**Start here:**

```bash
flutter run -d chrome
```

Then type: `Hello!`

**Have fun! 🚀**
