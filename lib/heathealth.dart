import 'package:flutter/material.dart';

class HeatHealthScreen extends StatelessWidget {
  const HeatHealthScreen({Key? key}) : super(key: key);

  @override
Widget build(BuildContext context) {
    const String content = '''
Anyone can suffer from heat-related health problems, but those more at-risk include:

1. People over 65 years
2. Babies and young children
3. Pregnant women
4. People who have existing medical conditions, such as cardiovascular disease, kidney disease, diabetes, or mental illness
5. People on certain medications including diuretics (fluid tablets), beta-blockers, drugs with anticholinergic properties, and central nervous system stimulants
6. People who work or exercise outdoors
7. People who are socially isolated or living alone, because there may not be someone to support or check in with them during extreme heat.
8. People with limited ways to keep cool, such as air conditioning, including people living in buildings that heat up easily or people who are experiencing homelessness.

During hot weather, our bodies work to prevent overheating by sweating and redirecting blood flow to the skin. People can also take actions such as staying cool using air-conditioning, and drinking more water than usual. Heat-related health problems happen when these protective changes in the body, combined with the actions people take are not enough to avoid overheating or dehydration, and organ systems begin to malfunction.

Heat-related health problems occur through several pathways:

A major rise in body temperature, due to a build-up of heat, leads to conditions such as heat exhaustion, and eventually heat stroke, which is a medical emergency.
The redirection of blood flow to the skin, means that the heart must work harder than normal. Strain on the heart can cause problems for people with existing heart conditions, for example by triggering a heart attack.
An increase in sweating can lead to dehydration if fluid loss is not replaced by drinking enough. Dehydration can cause weakness and fainting, lead to kidney problems and worsen other medical conditions.

Dehydration

Dehydration occurs when the body doesn’t have enough fluid to carry out its normal functions.

Symptoms of dehydration include:

Thirst
Dry mouth
Passing less urine than usual
Dark or strong-smelling urine
Dizziness or headache
Irritability or difficultly thinking clearly.
First aid for dehydration due to heat includes:

Move to a cool area and rest.
Drink plenty of fluids.
Remove unnecessary clothing.
Cool down by wetting the skin with cool water.
See a doctor if there is no improvement or you are concerned.

Heat exhaustion

Heat exhaustion is a serious condition that can progress to heatstroke. It can occur when core body temperature rises to 38-39°C.

Signs and symptoms of heat exhaustion include:

Heavy sweating
Pale skin
Muscle cramps
Weakness
Dizziness, headache
Nausea, vomiting
Fainting
Rapid pulse.

Heatstroke

Heatstroke can occur when the core body temperature rises above 40 °C and blood flow to internal organs is restricted. Many organs in the body suffer damage and the body temperature must be reduced quickly.

Heatstroke may appear similar to heat exhaustion, but the skin may be dry with no sweating and the person may appear confused or agitated. Signs and symptoms include:

Confusion or agitation
Loss of consciousness
Profuse sweating or hot, dry skin
Muscle twitching or seizures
Rapid breathing
Rapid pulse
Very high body temperature.

Heat cramps

Heat cramp symptoms include muscle pains or spasms, usually in the abdomen, arms or legs.

Cramps may occur after strenuous activity in a hot environment, when the body gets depleted of salt and water.

Heat cramps may also be a symptom of heat exhaustion.

First aid for heat cramps includes:

Rest in a cool place.
Increase fluid intake.
Rest a few hours before returning to activity.
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
                'Heat-Related Illnesses',
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
