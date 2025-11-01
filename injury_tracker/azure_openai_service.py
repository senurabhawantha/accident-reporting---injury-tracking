import os
from typing import Dict, List
from openai import AzureOpenAI
from dotenv import load_dotenv

load_dotenv()


class FirstAidRecommendation:
    """Generate first aid recommendations using Azure OpenAI."""
    
    def __init__(self):
        """Initialize Azure OpenAI client."""
        self.client = AzureOpenAI(
            api_key=os.getenv('AZURE_OPENAI_API_KEY'),
            api_version=os.getenv('AZURE_OPENAI_API_VERSION'),
            azure_endpoint=os.getenv('AZURE_OPENAI_ENDPOINT')
        )
        self.deployment_name = os.getenv('AZURE_OPENAI_DEPLOYMENT_NAME')
    
    def get_recommendations(
        self,
        severity: str,
        confidence: float,
        wound_type: str = "general wound"
    ) -> Dict[str, any]:
        """
        Get first aid recommendations based on wound severity.
        
        Args:
            severity: Wound severity (mild, moderate, severe)
            confidence: Confidence score of the prediction
            wound_type: Type of wound (optional)
            
        Returns:
            Dictionary containing recommendations and emergency info
        """
        prompt = self._create_prompt(severity, wound_type)
        
        try:
            response = self.client.chat.completions.create(
                model=self.deployment_name,
                messages=[
                    {
                        "role": "system",
                        "content": """You are a professional medical first aid assistant. 
                        Provide clear, concise, and actionable first aid recommendations. 
                        Always emphasize when professional medical help is needed. 
                        Format your response with clear sections: Immediate Actions, 
                        First Aid Steps, Warning Signs, and When to Seek Medical Help."""
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                temperature=0.7,
                max_tokens=800
            )
            
            recommendation_text = response.choices[0].message.content
            
            # Parse the response
            parsed_recommendations = self._parse_recommendations(recommendation_text)
            
            # Add metadata
            result = {
                'severity': severity,
                'confidence': confidence,
                'wound_type': wound_type,
                'recommendations': parsed_recommendations,
                'emergency_info': self._get_emergency_info(severity),
                'disclaimer': 'This is AI-generated first aid guidance. For serious injuries, always seek professional medical help immediately.'
            }
            
            return result
            
        except Exception as e:
            # Fallback to basic recommendations if API fails
            return self._get_fallback_recommendations(severity, confidence, wound_type)
    
    def _create_prompt(self, severity: str, wound_type: str) -> str:
        """Create a detailed prompt for Azure OpenAI."""
        return f"""
        A person has a {severity} {wound_type} injury. 
        
        Severity Level: {severity.upper()}
        
        Please provide:
        1. Immediate Actions: What should be done right now
        2. First Aid Steps: Step-by-step instructions (numbered list)
        3. Things to Avoid: What NOT to do
        4. Warning Signs: Signs that indicate the situation is worsening
        5. When to Seek Medical Help: Clear criteria for when professional help is needed
        6. Expected Healing Time: Approximate recovery timeline
        
        Keep instructions clear, concise, and easy to follow in an emergency situation.
        """
    
    def _parse_recommendations(self, text: str) -> Dict[str, any]:
        """Parse the AI response into structured format."""
        sections = {
            'immediate_actions': '',
            'first_aid_steps': [],
            'things_to_avoid': [],
            'warning_signs': [],
            'when_to_seek_help': '',
            'healing_time': ''
        }
        
        # Simple parsing (you can enhance this with more sophisticated parsing)
        lines = text.split('\n')
        current_section = None
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # Detect sections
            if 'immediate action' in line.lower():
                current_section = 'immediate_actions'
            elif 'first aid step' in line.lower():
                current_section = 'first_aid_steps'
            elif 'avoid' in line.lower() or 'do not' in line.lower():
                current_section = 'things_to_avoid'
            elif 'warning sign' in line.lower():
                current_section = 'warning_signs'
            elif 'seek' in line.lower() and 'help' in line.lower():
                current_section = 'when_to_seek_help'
            elif 'healing' in line.lower() or 'recovery' in line.lower():
                current_section = 'healing_time'
            elif current_section and not line.startswith('#'):
                # Add content to current section
                if current_section in ['first_aid_steps', 'things_to_avoid', 'warning_signs']:
                    # Remove numbering and bullets
                    cleaned = line.lstrip('0123456789.-•* ')
                    if cleaned:
                        sections[current_section].append(cleaned)
                else:
                    sections[current_section] += line + ' '
        
        # Clean up text sections
        for key in ['immediate_actions', 'when_to_seek_help', 'healing_time']:
            sections[key] = sections[key].strip()
        
        return sections
    
    def _get_emergency_info(self, severity: str) -> Dict[str, any]:
        """Get emergency information based on severity."""
        emergency_info = {
            'mild': {
                'urgency': 'low',
                'call_emergency': False,
                'message': 'Monitor the wound. Seek medical help if it worsens or shows signs of infection.'
            },
            'moderate': {
                'urgency': 'medium',
                'call_emergency': False,
                'message': 'Consider visiting a doctor or urgent care facility, especially if bleeding persists or you notice signs of infection.'
            },
            'severe': {
                'urgency': 'high',
                'call_emergency': True,
                'message': 'SEEK IMMEDIATE MEDICAL ATTENTION. Call emergency services if bleeding is severe, victim is unconscious, or showing signs of shock.'
            }
        }
        
        return emergency_info.get(severity, emergency_info['moderate'])
    
    def _get_fallback_recommendations(
        self,
        severity: str,
        confidence: float,
        wound_type: str
    ) -> Dict[str, any]:
        """Provide basic fallback recommendations if API fails."""
        fallback = {
            'mild': {
                'immediate_actions': 'Clean the wound with clean water or saline solution.',
                'first_aid_steps': [
                    'Wash your hands thoroughly',
                    'Clean the wound gently with water',
                    'Apply antiseptic if available',
                    'Cover with a sterile bandage',
                    'Keep the wound clean and dry'
                ],
                'things_to_avoid': [
                    'Do not use dirty materials',
                    'Avoid touching the wound with unwashed hands',
                    'Do not remove bandage too frequently'
                ],
                'warning_signs': [
                    'Increased pain or redness',
                    'Pus or discharge',
                    'Fever',
                    'Red streaks from wound'
                ],
                'when_to_seek_help': 'If wound shows signs of infection or does not heal within a week',
                'healing_time': '3-7 days with proper care'
            },
            'moderate': {
                'immediate_actions': 'Apply pressure to stop bleeding, elevate if possible.',
                'first_aid_steps': [
                    'Apply direct pressure with clean cloth',
                    'Elevate the injured area above heart level',
                    'Once bleeding stops, clean gently',
                    'Apply antibiotic ointment',
                    'Cover with sterile dressing',
                    'Change dressing daily'
                ],
                'things_to_avoid': [
                    'Do not remove embedded objects',
                    'Avoid using cotton directly on wound',
                    'Do not apply tourniquets unless absolutely necessary'
                ],
                'warning_signs': [
                    'Bleeding that won\'t stop after 10 minutes',
                    'Severe pain',
                    'Signs of infection',
                    'Numbness or loss of function'
                ],
                'when_to_seek_help': 'Seek medical attention within 24 hours or sooner if bleeding persists',
                'healing_time': '1-3 weeks depending on wound size'
            },
            'severe': {
                'immediate_actions': 'CALL EMERGENCY SERVICES IMMEDIATELY. Apply firm pressure to control bleeding.',
                'first_aid_steps': [
                    'Call 911 or emergency services immediately',
                    'Apply firm, direct pressure with clean cloth',
                    'Do not remove cloth even if blood soaks through, add more layers',
                    'Keep person still and calm',
                    'Monitor breathing and consciousness',
                    'Treat for shock if necessary'
                ],
                'things_to_avoid': [
                    'Do not remove embedded objects',
                    'Do not move the person unnecessarily',
                    'Do not give anything to eat or drink',
                    'Do not try to clean severe wounds'
                ],
                'warning_signs': [
                    'Heavy bleeding',
                    'Signs of shock (pale, rapid pulse, confusion)',
                    'Loss of consciousness',
                    'Difficulty breathing'
                ],
                'when_to_seek_help': 'IMMEDIATE MEDICAL ATTENTION REQUIRED - Call emergency services now',
                'healing_time': 'Requires medical intervention - timeline determined by healthcare provider'
            }
        }
        
        recommendations = fallback.get(severity, fallback['moderate'])
        
        return {
            'severity': severity,
            'confidence': confidence,
            'wound_type': wound_type,
            'recommendations': recommendations,
            'emergency_info': self._get_emergency_info(severity),
            'disclaimer': 'This is basic first aid guidance. For serious injuries, always seek professional medical help immediately.'
        }
