import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped network schedule.
    final class CappedNetworkScheduleView {
        var codeText: String
        var labelText: String
        var country: String
        var archived: String
        var active: String
        var scoreText: String
        var statusLabel: String

        init(codeText: String, labelText: String, country: String, archived: String, active: String, scoreText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.country = country
            self.archived = archived
            self.active = active
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedNetworkScheduleView(_ item: CappedNetworkSchedule) -> CappedNetworkScheduleView {
        return CappedNetworkScheduleView(
            codeText: item.code,
            labelText: item.label,
            country: item.country,
            archived: "\(item.archived)",
            active: "\(item.active)",
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedNetworkScheduleViews(_ items: [CappedNetworkSchedule]) -> [CappedNetworkScheduleView] {
        var views: [CappedNetworkScheduleView] = []
        for item in items {
            views.append(toCappedNetworkScheduleView(item))
        }
        return views
    }

    static func sumCappedNetworkScheduleView(_ view: CappedNetworkScheduleView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
