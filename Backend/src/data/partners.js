const { v4: uuidv4 } = require('uuid');

const partnersStack = [
  {
    id: uuidv4(),
    name: 'Alex',
    age: 28,
    bio: 'Love outdoor bouldering and sport climbing. Always up for a weekend adventure!',
    skillLevel: 'Advanced',
    preferredTypes: ['Bouldering', 'Sport Climbing', 'Outdoor'],
    location: 'Boulder, CO',
    profileImageName: 'person.circle.fill',
    availability: 'Weekends',
    favoriteCrag: 'Eldorado Canyon',
  },
  {
    id: uuidv4(),
    name: 'Jordan',
    age: 32,
    bio: 'Indoor climber looking to transition to outdoor. Patient and supportive partner!',
    skillLevel: 'Intermediate',
    preferredTypes: ['Indoor', 'Sport Climbing'],
    location: 'Denver, CO',
    profileImageName: 'person.circle.fill',
    availability: 'Evenings & Weekends',
    favoriteCrag: null,
  },
  {
    id: uuidv4(),
    name: 'Sam',
    age: 25,
    bio: 'Trad climber with 5 years experience. Safety first, fun always!',
    skillLevel: 'Expert',
    preferredTypes: ['Traditional', 'Outdoor'],
    location: 'Golden, CO',
    profileImageName: 'person.circle.fill',
    availability: 'Flexible',
    favoriteCrag: 'The Garden of the Gods',
  },
  {
    id: uuidv4(),
    name: 'Casey',
    age: 29,
    bio: 'Bouldering enthusiast! Love challenging problems and good vibes.',
    skillLevel: 'Intermediate',
    preferredTypes: ['Bouldering', 'Indoor', 'Outdoor'],
    location: 'Fort Collins, CO',
    profileImageName: 'person.circle.fill',
    availability: 'Weekends',
    favoriteCrag: 'Horsetooth Reservoir',
  },
  {
    id: uuidv4(),
    name: 'Morgan',
    age: 35,
    bio: 'Multi-pitch enthusiast. Looking for reliable partners for big wall adventures.',
    skillLevel: 'Expert',
    preferredTypes: ['Traditional', 'Sport Climbing', 'Outdoor'],
    location: 'Estes Park, CO',
    profileImageName: 'person.circle.fill',
    availability: 'Weekends',
    favoriteCrag: 'Lumpy Ridge',
  },
];

module.exports = partnersStack;


