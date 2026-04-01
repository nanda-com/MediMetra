import os
import google.generativeai as genai
import json
from dotenv import load_dotenv
import logging
from PIL import Image

logger = logging.getLogger(__name__)
load_dotenv()

# Initialize API Key
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
else:
    logger.warning("Warning: GEMINI_API_KEY missing from .env File.")

def parse_medical_report_with_ai(image_path: str):
    """
    Feeds a local medical report image into the Gemini 1.5 Flash Vision model.
    It rigorously forces the AI to extract exactly the medication title and duration into a JSON array,
    ignoring all fluff.
    """
    try:
        # Load the uploaded file using Pillow
        img = Image.open(image_path)
        
        # Instantiate the fast multi-modal Gemini Flash model
        model = genai.GenerativeModel('gemini-1.5-flash')
        
        # Construct an airtight prompt enforcing JSON response
        prompt = '''
        You are an expert medical AI system reading a Patient Visit Summary or medical bill.
        I am providing you an image of a medical report. 

        Extract all the medications, treatments, or tests that the patient actively needs to follow.
        For each item, determine:
        1. The concise title (e.g. "Amoxicillin")
        2. The recommended duration in total days (e.g. 10). If not specified, default to 1.
        
        Return ONLY a raw, pure JSON list of objects matching this exact schema:
        [
            {
                "title": "Amoxicillin",
                "duration_days": 10
            }
        ]
        
        Do not include markdown tags like ```json. Do not include any prefix or suffix strings.
        Output ONLY the raw JSON string starting with `[` and ending with `]`.
        '''
        
        logger.info(f"Sending image {image_path} to Gemini AI...")
        response = model.generate_content([prompt, img])
        response_text = response.text.strip()
        
        # Fallback strip if Gemini disobeys markdown instructions
        if response_text.startswith("```json"):
            response_text = response_text[7:-3].strip()
        elif response_text.startswith("```"):
            response_text = response_text[3:-3].strip()
            
        # Parse output into Python list
        medications_array = json.loads(response_text)
        logger.info(f"Successfully processed AI response: {medications_array}")
        
        return medications_array
        
    except json.JSONDecodeError as e:
        logger.error(f"AI returned invalid JSON: {response.text}")
        return []
    except Exception as e:
        logger.error(f"Error parsing image with Gemini: {str(e)}")
        return []
