import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional float pool summary.
    final class RegionalFloatPoolSummaryView {
        var code: String
        var title: String
        var maximumText: String
        var ceiling: String
        var score: String
        var specialty: String
        var amount: String
        var wardText: String
        var discount: String
        var statusLabel: String

        init(code: String, title: String, maximumText: String, ceiling: String, score: String, specialty: String, amount: String, wardText: String, discount: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.maximumText = maximumText
            self.ceiling = ceiling
            self.score = score
            self.specialty = specialty
            self.amount = amount
            self.wardText = wardText
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalFloatPoolSummaryView(_ item: RegionalFloatPoolSummary) -> RegionalFloatPoolSummaryView {
        return RegionalFloatPoolSummaryView(
            code: item.code,
            title: item.title,
            maximumText: String(format: "%.2f", item.maximum),
            ceiling: String(format: "%.2f", item.ceiling),
            score: String(format: "%.2f", item.score),
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            amount: String(format: "%.2f", item.amount),
            wardText: item.ward,
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalFloatPoolSummaryViews(_ items: [RegionalFloatPoolSummary]) -> [RegionalFloatPoolSummaryView] {
        var views: [RegionalFloatPoolSummaryView] = []
        for item in items {
            views.append(toRegionalFloatPoolSummaryView(item))
        }
        return views
    }

    static func sumRegionalFloatPoolSummaryView(_ view: RegionalFloatPoolSummaryView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedMaximum + parsedCeiling + parsedScore
    }
}
