import SwiftUI

struct Habit: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var timeLocation: String
    var typeOfPerson: String
}

struct HabitStatus: Identifiable, Equatable {
    let id = UUID()
    var habit: Habit
    var completionDates: [Date] = []
}

struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Welcome Elvira")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .padding()
            Spacer()
        }
        .background(Color.white)
        .ignoresSafeArea()
    }
}

struct ContentView: View {
    @State private var showingAddHabit = false
    @State private var habits: [Habit] = []
    @State private var habitStatuses: [HabitStatus] = []
    @State private var selectedHabit: Habit?
    @State private var isLoading = true
    
    var body: some View {
        if isLoading {
            LoadingView()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isLoading = false
                        }
                    }
                }
        } else {
            TabView {
                HomeView(title: "Today", habitStatuses: $habitStatuses, habits: $habits, showingAddHabit: $showingAddHabit, selectedHabit: $selectedHabit, isToday: true)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Today")
                    }
                
                HomeView(title: "Yesterday", habitStatuses: $habitStatuses, habits: $habits, showingAddHabit: $showingAddHabit, selectedHabit: $selectedHabit, isToday: false)
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Yesterday")
                    }
                
                ProgressView(habits: $habits, habitStatuses: $habitStatuses)
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Progress")
                    }
            }
        }
    }
}

struct HomeView: View {
    var title: String
    @Binding var habitStatuses: [HabitStatus]
    @Binding var habits: [Habit]
    @Binding var showingAddHabit: Bool
    @Binding var selectedHabit: Habit?
    var isToday: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    ForEach(habitStatuses) { habitStatus in
                        HabitCardView(habitStatus: habitStatus, isToday: isToday)
                            .onTapGesture {
                                if let index = habitStatuses.firstIndex(of: habitStatus) {
                                    let currentDate = Calendar.current.startOfDay(for: Date())
                                    if isToday {
                                        if habitStatuses[index].completionDates.contains(currentDate) {
                                            habitStatuses[index].completionDates.removeAll { $0 == currentDate }
                                        } else {
                                            habitStatuses[index].completionDates.append(currentDate)
                                        }
                                    } else {
                                        let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
                                        if habitStatuses[index].completionDates.contains(yesterdayDate) {
                                            habitStatuses[index].completionDates.removeAll { $0 == yesterdayDate }
                                        } else {
                                            habitStatuses[index].completionDates.append(yesterdayDate)
                                        }
                                    }
                                }
                            }
                            .contextMenu {
                                Button(action: {
                                    selectedHabit = habitStatus.habit
                                    showingAddHabit = true
                                }) {
                                    Text("Edit")
                                    Image(systemName: "pencil")
                                }
                                Button(action: {
                                    if let index = habitStatuses.firstIndex(of: habitStatus) {
                                        habitStatuses.remove(at: index)
                                    }
                                }) {
                                    Text("Delete")
                                    Image(systemName: "trash")
                                }
                            }
                    }
                }
                .padding()
            }
            .navigationBarTitle(title)
            .navigationBarItems(trailing: Button(action: {
                showingAddHabit.toggle()
            }) {
                Text("+ Habits")
            })
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(habits: $habits, habitStatuses: $habitStatuses, selectedHabit: $selectedHabit, showingAddHabit: $showingAddHabit)
            }
        }
    }
}

struct HabitCardView: View {
    var habitStatus: HabitStatus
    var isToday: Bool
    
    var body: some View {
        let currentDate = Calendar.current.startOfDay(for: Date())
        let relevantDate = isToday ? currentDate : Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
        let isCompleted = habitStatus.completionDates.contains(relevantDate)
        
        return VStack(alignment: .leading) {
            Text(habitStatus.habit.title)
                .font(.headline)
                .padding(.bottom, 2)
            Text(habitStatus.habit.timeLocation)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(habitStatus.habit.typeOfPerson)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isCompleted ? Color.green.opacity(0.7) : Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.vertical, 5)
    }
}

struct AddHabitView: View {
    @Binding var habits: [Habit]
    @Binding var habitStatuses: [HabitStatus]
    @Binding var selectedHabit: Habit?
    @Binding var showingAddHabit: Bool
    
    @State private var title = ""
    @State private var timeLocation = ""
    @State private var typeOfPerson = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Habit")) {
                    TextField("Title", text: $title)
                    TextField("Time/Location", text: $timeLocation)
                    TextField("Type of Person", text: $typeOfPerson)
                }
            }
            .navigationBarTitle("New Habit", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                showingAddHabit = false
            }, trailing: Button("Save") {
                if let selectedHabit = selectedHabit {
                    if let index = habits.firstIndex(of: selectedHabit) {
                        habits[index].title = title
                        habits[index].timeLocation = timeLocation
                        habits[index].typeOfPerson = typeOfPerson
                        if let statusIndex = habitStatuses.firstIndex(where: { $0.habit.id == selectedHabit.id }) {
                            habitStatuses[statusIndex].habit = habits[index]
                        }
                    }
                } else {
                    let newHabit = Habit(title: title, timeLocation: timeLocation, typeOfPerson: typeOfPerson)
                    habits.append(newHabit)
                    habitStatuses.append(HabitStatus(habit: newHabit))
                }
                showingAddHabit = false
            })
            .onAppear {
                if let selectedHabit = selectedHabit {
                    title = selectedHabit.title
                    timeLocation = selectedHabit.timeLocation
                    typeOfPerson = selectedHabit.typeOfPerson
                }
            }
        }
    }
}

struct ProgressView: View {
    @Binding var habits: [Habit]
    @Binding var habitStatuses: [HabitStatus]
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Habit Count")) {
                        ForEach(habitStatuses) { habitStatus in
                            let totalCount = habitStatus.completionDates.count
                            let streakCount = calculateStreak(for: habitStatus.completionDates)
                            
                            VStack(alignment: .leading) {
                                Text(habitStatus.habit.title)
                                    .font(.headline)
                                Text("Total days completed: \(totalCount)")
                                Text("Consecutive days streak: \(streakCount)")
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarTitle("Progress")
        }
    }
    
    func calculateStreak(for dates: [Date]) -> Int {
        let sortedDates = dates.sorted()
        var streak = 0
        var currentStreak = 0
        var previousDate: Date?
        
        for date in sortedDates {
            if let previousDate = previousDate {
                if Calendar.current.isDate(date, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: previousDate)!) {
                    currentStreak += 1
                } else {
                    streak = max(streak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            previousDate = date
        }
        
        return max(streak, currentStreak)
    }
}

@main
struct HabitsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
