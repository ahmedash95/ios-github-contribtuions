import SwiftUI
import Combine

struct ContributionChartView: View {
    let contributions: [ContributionDay]
    let customColor: Color
    let compact: Bool
    
    @State private var selectedDay: ContributionDay?
    @State private var showingDetail = false
    
    init(contributions: [ContributionDay], customColor: Color = .green, compact: Bool = false) {
        self.contributions = contributions
        self.customColor = customColor
        self.compact = compact
    }
    
    var body: some View {
        if compact {
            compactChart
        } else {
            regularChart
        }
    }
    
    private var compactChart: some View {
        HStack(spacing: 1) {
            ForEach(Array(weeklyGroupedContributions(last84Days).enumerated()), id: \.offset) { weekIndex, week in
                VStack(spacing: 1) {
                    ForEach(Array(week.enumerated()), id: \.offset) { dayIndex, day in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(getColor(for: day.contributionCount))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .onTapGesture {
                                selectedDay = day
                                showingDetail = true
                            }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .alert("Contribution Details", isPresented: $showingDetail) {
            Button("OK") { }
        } message: {
            if let day = selectedDay {
                Text("\(day.contributionCount) contributions on \(formatDate(day.date))")
            }
        }
    }
    
    private var regularChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 1) {
                ForEach(Array(weeklyGroupedContributions(last112Days).enumerated()), id: \.offset) { weekIndex, week in
                    VStack(spacing: 1) {
                        ForEach(Array(week.enumerated()), id: \.offset) { dayIndex, day in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(getColor(for: day.contributionCount))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .onTapGesture {
                                    selectedDay = day
                                    showingDetail = true
                                }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            contributionSummary
        }
        .alert("Contribution Details", isPresented: $showingDetail) {
            Button("OK") { }
        } message: {
            if let day = selectedDay {
                Text("\(day.contributionCount) contributions on \(formatDate(day.date))")
            }
        }
    }
    
    private var contributionSummary: some View {
        HStack {
            Text("\(totalContributions) contributions")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 2) {
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(level == 0 ? Color(.systemGray5) : customColor.opacity(max(0.6, Double(level) * 0.25)))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func weeklyGroupedContributions(_ contributions: [ContributionDay]) -> [[ContributionDay]] {
        var weeks: [[ContributionDay]] = []
        
        // Simply group every 7 consecutive days into a column
        for i in stride(from: 0, to: contributions.count, by: 7) {
            let endIndex = min(i + 7, contributions.count)
            let week = Array(contributions[i..<endIndex])
            weeks.append(week)
        }
        
        return weeks
    }
    
    private var last84Days: [ContributionDay] {
        Array(contributions.suffix(84))
    }
    
    private var last112Days: [ContributionDay] {
        Array(contributions.suffix(112))
    }
    
    private var totalContributions: Int {
        (compact ? last84Days : last112Days).reduce(0) { $0 + $1.contributionCount }
    }
    
    private func getColor(for count: Int) -> Color {
        let intensity = GitHubService.shared.getContributionIntensity(count: count)
        if intensity == 0.0 {
            return Color(.systemGray5)
        } else {
            return customColor.opacity(max(0.6, intensity))
        }
    }
}