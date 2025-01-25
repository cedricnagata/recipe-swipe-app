import SwiftUI

struct PreferencesView: View {
    @State private var cookingSkillLevel = "beginner"
    @State private var dietaryRestrictions: Set<String> = []
    @State private var kitchenEquipment: [String: Bool] = [
        "Oven": true,
        "Stovetop": true,
        "Microwave": true,
        "Blender": false,
        "Food Processor": false,
        "Stand Mixer": false,
        "Slow Cooker": false,
        "Pressure Cooker": false
    ]
    @State private var favoriteCuisines: Set<String> = []
    
    let skillLevels = ["beginner", "intermediate", "advanced"]
    let cuisineTypes = ["Italian", "Mexican", "Chinese", "Japanese", "Indian", "American", "French", "Mediterranean", "Thai", "Korean"]
    let dietaryOptions = ["Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free", "Nut-Free", "Halal", "Kosher", "Pescatarian"]
    
    var body: some View {
        Form {
            // Cooking Skill Level
            Section("Cooking Experience") {
                Picker("Skill Level", selection: $cookingSkillLevel) {
                    ForEach(skillLevels, id: \.self) { level in
                        Text(level.capitalized)
                            .tag(level)
                    }
                }
            }
            
            // Dietary Restrictions
            Section("Dietary Restrictions") {
                ForEach(dietaryOptions, id: \.self) { restriction in
                    Toggle(restriction, isOn: binding(for: restriction, in: $dietaryRestrictions))
                }
            }
            
            // Kitchen Equipment
            Section("Available Equipment") {
                ForEach(Array(kitchenEquipment.keys.sorted()), id: \.self) { equipment in
                    Toggle(equipment, isOn: bindingForEquipment(equipment))
                }
            }
            
            // Favorite Cuisines
            Section("Favorite Cuisines") {
                ForEach(cuisineTypes, id: \.self) { cuisine in
                    Toggle(cuisine, isOn: binding(for: cuisine, in: $favoriteCuisines))
                }
            }
            
            Section {
                Button(action: savePreferences) {
                    Text("Save Preferences")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                }
                .listRowBackground(Color.blue)
            }
        }
        .navigationTitle("Preferences")
        .onAppear(perform: loadPreferences)
    }
    
    private func binding(for item: String, in set: Binding<Set<String>>) -> Binding<Bool> {
        Binding(
            get: { set.wrappedValue.contains(item) },
            set: { isEnabled in
                if isEnabled {
                    set.wrappedValue.insert(item)
                } else {
                    set.wrappedValue.remove(item)
                }
            }
        )
    }
    
    private func bindingForEquipment(_ equipment: String) -> Binding<Bool> {
        Binding(
            get: { kitchenEquipment[equipment] ?? false },
            set: { newValue in
                kitchenEquipment[equipment] = newValue
            }
        )
    }
    
    private func loadPreferences() {
        // TODO: Load preferences from backend
    }
    
    private func savePreferences() {
        // TODO: Save preferences to backend
    }
}

#Preview {
    NavigationStack {
        PreferencesView()
    }
}