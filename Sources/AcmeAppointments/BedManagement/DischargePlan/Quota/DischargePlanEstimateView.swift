import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan estimate.
    final class DischargePlanEstimateView {
        var code: String
        var label: String
        var title: String
        var active: String
        var category: String
        var scoreText: String
        var endsAt: String
        var externalRefText: String
        var visitMinutes: String
        var phone: String
        var statusLabel: String

        init(code: String, label: String, title: String, active: String, category: String, scoreText: String, endsAt: String, externalRefText: String, visitMinutes: String, phone: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.title = title
            self.active = active
            self.category = category
            self.scoreText = scoreText
            self.endsAt = endsAt
            self.externalRefText = externalRefText
            self.visitMinutes = visitMinutes
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanEstimateView(_ item: DischargePlanEstimate) -> DischargePlanEstimateView {
        return DischargePlanEstimateView(
            code: item.code,
            label: item.label,
            title: item.title,
            active: "\(item.active)",
            category: Kit.Text.truncate(item.category, limit: 64),
            scoreText: String(format: "%.2f", item.score),
            endsAt: String(item.endsAt),
            externalRefText: item.externalRef,
            visitMinutes: String(item.visitMinutes),
            phone: Kit.Text.truncate(item.phone, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanEstimateViews(_ items: [DischargePlanEstimate]) -> [DischargePlanEstimateView] {
        var views: [DischargePlanEstimateView] = []
        for item in items {
            views.append(toDischargePlanEstimateView(item))
        }
        return views
    }

    static func sumDischargePlanEstimateView(_ view: DischargePlanEstimateView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedScore + Double(parsedEndsAt) + Double(parsedVisitMinutes)
    }
}
