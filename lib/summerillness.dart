import 'package:flutter/material.dart';

class SummerIllnessesScreen extends StatelessWidget {
  const SummerIllnessesScreen({Key? key}) : super(key: key);

  @override
    Widget build(BuildContext context) {
    const String content = '''
The dry season in the Philippines falls within the months of March to May. More commonly known as summer, this is the period when people usually go to the beach or air-conditioned shopping and dining establishments to escape the heat. However, due to the ongoing pandemic, we’re advised to endure the heat in the safety of our homes.
      
During this season, certain diseases are more common due to rising temperatures that can reach dangerous levels. It is also ideal for pathogens to thrive and spread in such conditions. Summer sicknesses range from sore eyes to skin conditions and asthma—the list goes on. Health problems arising from these illnesses should not be ignored, nor should they prevent anyone from having a relaxing summertime.
      
1. Asthma
Heat and humidity can trigger asthma symptoms like coughing and shortness of breath, as lack of air movement can trap pollutants like dust and molds into the airways.
 
Staying cool amidst the summer’s extreme heat is crucial in preventing asthma attacks. Taking shelter in clean, cool, and well-ventilated places should help someone with asthma combat the heat. Medications need to be close by as well, just in case of a sudden attack.
 

2. Chickenpox
Chickenpox is a viral infection that typically affects children, which is why the first dose of varicella vaccine should be given to kids between ages 12 and 15 months and the second dose from age 4 to 6.
 
Initial chickenpox symptoms include fever and headache, while rashes may start appearing a week after exposure to the virus and develop into blisters that take several days to heal. Since chickenpox can be transmitted through direct contact with the rash or inhalation of air droplets, those who are sick should avoid going to public areas to prevent the infection from spreading.
 

3. Conjunctivitis (sore eyes)
In sore eyes or conjunctivitis, the outer lining around the eyeball and the inner lining of the eyelid become inflamed. This may be due to a viral or bacterial infection that thrive during the season, an allergic reaction, or trauma. The conjunctiva—or the covering of the white part of the eyes—may show redness, with noticeable itching and discharge around the eyes, too.
 
The best and easiest way to avoid getting sore eyes is frequent and thorough hand washing, as this removes bacteria or any other foreign substance from the hands so they do not get into the face or eyes.
 

4. Flu
Although influenza viruses are also prevalent in cold weather, they can still cause summer flu. Weather changes, like sudden downpours or temperature shifts from hot outdoor to cool indoor environments and vice versa, can make someone susceptible to respiratory diseases like cough and colds. Other symptoms of flu include fever, muscle aches, and headache.
 
Bedrest, antiviral medications, and adequate fluid intake are effective in alleviating flu symptoms.
 

5. Food poisoning
Foodborne illnesses are twice more common during the summer season than other months of the year since food spoils easily—no thanks to bacteria that thrive on warm weather conditions. Contaminated food and drinks can cause diarrhea and vomiting, which can lead to dehydration and, possibly, complications for those with chronic health conditions.

It is best to avoid eating perishable foods one to two hours after being left out of the refrigerator or as soon as the food develops molds or an unpleasant smell.
 

6. Hyperthermia
Hyperthermia is a condition where the body temperature becomes abnormally high, signaling that it cannot regulate heat coming from the environment. Heat exhaustion and heat stroke are medical emergencies that fall under hyperthermia.

A person suffering from hyperthermia may experience headache, dizziness, disorientation, fainting, heavy sweating, and cramps. Avoid strenuous activities or going outdoors in the middle of the day when the sun’s heat is at its peak.
 

7. Measles
A condition transmitted in the same way as chickenpox, measles is another example of a childhood illness that spreads during summer. The rubeola virus causes measles, with symptoms that include dry cough, high fever, runny nose, and reddening of the eyes.
 
Measles can also cause complications ranging from ear infections to pneumonia, including pregnancy problems for women. The MMR (measles, mumps, and rubella) vaccine is a way to give people immunity against the disease.
 

8. Mumps
Mumps is an infectious disease caused by a paramyxovirus that is spread through an infected person’s droplets of saliva. It is concentrated around the salivary glands near the ears, causing them to swell. This inflammation on one or both sides of the face may cause pain or difficulty in chewing or swallowing. Mumps may also be accompanied by a fever, headache, and muscle pains.
 
In most cases, mumps does not progress into a serious disease and can be eased by applying a warm or cold compress and taking pain relievers. However, people at risk of complications, such as pregnant women, should see a doctor specializing in infectious diseases.
 

9. Rabies
Summer outdoor activities can increase chance encounters with rabies-infected animals like cats, dogs, and bats, to mention a few, as they go to areas where they can find food or water. When someone exposes their broken skin to an infected animal’s saliva or is bitten by the animal, the rabies virus can then be transmitted to humans.

Preventive measures against rabies include vaccination of house pets and avoiding feeding wild animals. Those who were bitten by rabid animals should get rabies vaccination immediately.
 

10. Skin conditions
Sunburn is a common skin condition that happens when someone is in direct and prolonged exposure to the sun. The intense heat can cause first-degree burns with skin redness and peeling or second-degree burns with blisters.

Sunscreen with at least an SPF of 30 is the best preventive measure against exposure to harmful UV rays, while cool baths and moisturizers can ease the pain or discomfort from sunburns. In severe cases, a medical checkup may be necessary to treat skin blisters.
          ''';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo2.png',
              height: 40,
            ),
            const SizedBox(width: 10),
            const Text(
              'Weather-Being',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Common Summer Illnesses',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    height: 1.5, // Improves readability
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
