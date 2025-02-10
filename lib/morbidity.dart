import 'package:flutter/material.dart';

class MorbidityScreen extends StatelessWidget {
  const MorbidityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const String content = '''
People around the world are affected by extreme weather events, such as hurricanes or typhoons, floods, heat waves, wildfires, droughts, and snowstorms. While extreme events have occurred throughout Earth’s history, climate change may be increasing their intensity and occurrence.

Extreme weather events threaten human health and well-being. They can also disrupt the physical and social infrastructure people and communities rely on to stay safe and healthy before, during, and after a weather-related disaster.


The immediate effects on human health during extreme weather events can include exposure to the elements, mental health impacts, injury when attempting to escape, and even death caused by the weather event itself, such as drowning in a flood.

According to the U.S. Global Change Research Program’s National Climate Assessment, extreme weather events can also increase exposure to other environmental conditions that can harm health:

Hurricanes and coastal storms generate projectiles and debris that can cause injury during the event. They can also increase the potential for hazardous chemicals and waterborne and vector-borne pathogens to spread through communities and the environment due to facility damage, storm surge, and flooding.
Flood events and sea level rise can contaminate water with harmful bacteria and viruses that cause foodborne and waterborne illnesses.
When floodwaters recede from indoor spaces, there is increased risk of mold growth and impacted or poor indoor air quality. Exposure to mold spores can cause headaches and eye, nose, and throat irritation. Mold exposure can worsen lung diseases, such as asthma, and increase the risk for lung infection in immunocompromised individuals .
Wildfire smoke can travel long distances, potentially exposing people both near and far from the fire location to a mixture of respiratory irritants. When wildfires burn vegetation, like trees, they emit smoke that can harm lung and heart health. As wildfires move into residential areas, they burn homes and buildings, releasing toxic chemicals into the environment.
Extreme heat can lead to exhaustion, heat cramps, heat stroke, and heat-related death. People with chronic lung or heart illnesses or other conditions are at greater risk of heat-related complications or death.
Although everyone is vulnerable to health impacts associated with extreme weather events, some populations may be more vulnerable than others. Children, pregnant woman, older adults, people with outdoor jobs, and persons with disabilities or with preexisting health conditions may be disproportionately impacted. Additionally, individuals affected by poverty, communities that live near contaminated waste sites or industrial areas, and rural areas with limited health systems may be more impacted by extreme weather events.

The health effects of extreme weather are worsened when these events disrupt critical infrastructure, such as electricity, drinking and wastewater services, roads, and health care facilities. Because many of these systems rely on one another, disruption, or failure of one can result in the failure of others. For example, a storm that cripples a community’s electrical grid can also affect its water supply.
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
                'Weather-Related Morbidity',
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
