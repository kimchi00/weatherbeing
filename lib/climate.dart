import 'package:flutter/material.dart';

class ClimateChangeScreen extends StatelessWidget {
  const ClimateChangeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const String content = '''
Heat is an important environmental and occupational health hazard. Heat stress is the leading cause of weather-related deaths and can exacerbate underlying illnesses including cardiovascular disease, diabetes, mental health, asthma, and can increase the risk of accidents and transmission of some infectious diseases. Heatstroke is a medical emergency with a high-case fatality rate.
The number of people exposed to extreme heat is growing exponentially due to climate change in all world regions. Heat-related mortality for people over 65 years of age increased by approximately 85% between 2000–2004 and 2017–2021 (1). 
Between 2000–2019 studies show approximately 489 000 heat-related deaths occur each year, with 45% of these in Asia and 36% in Europe (2). In Europe alone in the summer of 2022, an estimated 61 672 heat-related excess deaths occurred (3). High intensity heatwave events can bring high acute mortality; in 2003, 70 000 people in Europe died as a result of the June–August event. In 2010, 56 000 excess deaths occurred during a 44–day heatwave in the Russian Federation.
Vulnerability to heat is shaped by both physiological factors, such as age and health status, and exposure factors such as occupation and socio-economic conditions.
The negative health impacts of heat are predictable and largely preventable with specific public health and multi-sectoral policies and interventions. WHO has issued guidance for public health institutions to identify and manage extreme heat risks. Action on climate change combined with comprehensive preparedness and risk management can save lives now and in the future.

A heatwave is a period where local excess heat accumulates over a sequence of unusually hot days and nights. Heatwaves and prolonged excess heat conditions are increasing in frequency, duration, intensity and magnitude due to climate change. Even low and moderate intensity heat waves can impact the health and well-being of vulnerable populations.

The frequency and intensity of extreme heat and heat waves will continue to rise in the 21st century because of climate change. Extended periods of high day and nighttime temperature conditions create cumulative stress on the human body, increasing the risk of illness and death from heat exposure. Heatwaves can acutely impact large populations for short periods of time, often trigger public health emergencies, and result in excess mortality and cascading socioeconomic impacts (for example, lost work capacity and labour productivity). They can also cause loss of health service delivery capacity, when power shortages accompany heatwaves and disrupt health facilities, transport and water infrastructure.

Population ageing and the growing prevalence of non-communicable diseases (respiratory and cardiovascular diseases, diabetes, dementia, renal disease and musculoskeletal disease) means that populations are becoming more susceptible to negative heat impacts. Cities are not being designed to minimize the accumulation and generation of urban heat, with a loss of greenspace and inappropriate housing materials (for example, metal roofs) that amplify human exposure to excess heat.

Awareness among health workers and the public remains insufficient of the health risks posed by heat. Health professionals should adjust their guidance, planning and interventions to account for increasing heat exposures, as well as to manage acute increases in admissions associated with heatwaves. Practical, feasible and often low-cost interventions at the individual, community, organizational, governmental and societal levels can save lives.
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
                'Climate Change and Health',
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
