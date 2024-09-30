import 'package:flutter/material.dart';
import 'package:weatherbeing/checklist.dart';
import 'package:weatherbeing/homepage.dart';
import 'package:weatherbeing/userprofile.dart';
import 'map.dart'; 

class HealthModule extends StatefulWidget {
  @override
  _HealthModuleState createState() => _HealthModuleState();
}

class _HealthModuleState extends State<HealthModule> {

  void _onItemTapped(int index) {
    setState(() {
    });

    // Check if the Health tab is tapped
    if (index == 0) {
      // Navigate to HealthModule when Health is selected
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChecklistPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserProfile()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo2.png', // Adjust the path as needed
              height: 40,
            ),
            SizedBox(width: 10),
            Text(
              'Weather-Being',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Recommendations Section
            _buildSectionTitle('General Recommendations'),
            SizedBox(height: 8),
            _buildRecommendationCard(
              'Lorem ipsum dolor sit amet consectetur. Habitant nunc suscipit nunc nibh dignissim.',
              Colors.lightGreenAccent,
              Icons.checkroom, // Example icon, change as needed
            ),
            SizedBox(height: 8),
            _buildRecommendationCard(
              'Lorem ipsum dolor sit amet consectetur. Sed tristique suscipit et in viverra mi consequat faucibus.',
              Colors.lightBlueAccent,
              Icons.water_drop, // Example icon, change as needed
            ),
            SizedBox(height: 20),

            // Specific Recommendations Section
            _buildSectionTitle('Specific Recommendations'),
            SizedBox(height: 8),
            _buildRecommendationCard(
              'Lorem ipsum dolor sit amet consectetur. Lectus dolor netus tellus nascetur egestas arcu diam. Praesent duis feugiat lacus turpis.',
              Colors.pinkAccent.shade100,
              Icons.healing, // Example icon, change as needed
            ),
            SizedBox(height: 8),
            _buildRecommendationCard(
              'Lorem ipsum dolor sit amet consectetur. Ultrices scelerisque ipsum non elementum. Tincidunt sed sit faucibus non nisl volutpat cras tellus amet.',
              Colors.amber.shade100,
              Icons.favorite, // Example icon, change as needed
            ),
            SizedBox(height: 20),

            // Illness Concentration Section
            _buildSectionTitle('Illness Concentration'),
            SizedBox(height: 8),
            _buildStaticMap(context), // Pass context for navigation
            SizedBox(height: 20),

            // Other Articles Section
            _buildSectionTitle('Other Articles'),
            SizedBox(height: 8),
            _buildArticleRow(
              'Lorem ipsum dolor sit amet consectetur. Ipsum amet ultricies imperdiet dui a vestibulum.',
              Colors.lightBlueAccent,
              'Lorem ipsum dolor sit amet consectetur. Nulla pretium diam in dui dui ipsum.',
              Colors.pinkAccent.shade100,
            ),
            SizedBox(height: 8),
            _buildArticleRow(
              'Lorem ipsum dolor sit amet consectetur. Venenatis dui maecenas aliquet ut sem blandit ac quam maecenas.',
              Colors.lightGreenAccent.shade100,
              'Lorem ipsum dolor sit amet consectetur. Eget malesuada lectus vitae diam quis massa quis neque varius.',
              Colors.grey.shade200,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Icon(Icons.info_outline, color: Colors.grey),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(width: 10),
          Icon(icon, size: 40, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildStaticMap(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MapWidget()), // Navigate to MapWidget on tap
        );
      },
      child: Container(
        height: 200,  // Fixed height for the map
        width: double.infinity,  // Full width of the container
        decoration: BoxDecoration(
          color: Colors.lightGreenAccent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/provinces-2k.png', // Replace with your static map image
            fit: BoxFit.cover, // Cover the entire container
            width: double.infinity, // Take up the full width
            height: 200, // Keep the image within the container's height
          ),
        ),
      ),
    );
  }

  Widget _buildArticleRow(String text1, Color color1, String text2, Color color2) {
    return Row(
      children: [
        Expanded(
          child: _buildArticleCard(text1, color1),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildArticleCard(text2, color2),
        ),
      ],
    );
  }

  Widget _buildArticleCard(String text, Color color) {
    return Container(
      width: 150,  // Fixed width for the card
      height: 150, // Fixed height for the card
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Center( // Center the text
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
          textAlign: TextAlign.center, // Center align the text
          maxLines: 5, // Limit to a maximum of 5 lines (adjust if necessary)
          overflow: TextOverflow.ellipsis, // Use ellipsis for overflow
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      currentIndex: 1,
      onTap: _onItemTapped, // This handles the tap and navigation logic
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Health',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle),
          label: 'Checklist',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
