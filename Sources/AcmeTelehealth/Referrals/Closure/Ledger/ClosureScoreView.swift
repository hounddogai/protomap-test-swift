import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure score.
    final class ClosureScoreView {
        var code: String
        var title: String
        var createdAt: String
        var ratio: String
        var minimum: String
        var patientRef: String
        var threshold: String
        var maximum: String
        var statusLabel: String

        init(code: String, title: String, createdAt: String, ratio: String, minimum: String, patientRef: String, threshold: String, maximum: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.ratio = ratio
            self.minimum = minimum
            self.patientRef = patientRef
            self.threshold = threshold
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toClosureScoreView(_ item: ClosureScore) -> ClosureScoreView {
        return ClosureScoreView(
            code: item.code,
            title: item.title,
            createdAt: String(item.createdAt),
            ratio: String(format: "%.2f", item.ratio),
            minimum: String(format: "%.2f", item.minimum),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            threshold: String(format: "%.2f", item.threshold),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureScoreViews(_ items: [ClosureScore]) -> [ClosureScoreView] {
        var views: [ClosureScoreView] = []
        for item in items {
            views.append(toClosureScoreView(item))
        }
        return views
    }

    static func sumClosureScoreView(_ view: ClosureScoreView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedCreatedAt) + parsedRatio + parsedMinimum
    }
}
