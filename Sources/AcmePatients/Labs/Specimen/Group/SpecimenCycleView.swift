import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen cycle.
    final class SpecimenCycleView {
        var code: String
        var name: String
        var ratio: String
        var country: String
        var activeText: String
        var scoreText: String
        var currency: String
        var amountText: String
        var margin: String
        var updatedAtText: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, name: String, ratio: String, country: String, activeText: String, scoreText: String, currency: String, amountText: String, margin: String, updatedAtText: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.country = country
            self.activeText = activeText
            self.scoreText = scoreText
            self.currency = currency
            self.amountText = amountText
            self.margin = margin
            self.updatedAtText = updatedAtText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenCycleView(_ item: SpecimenCycle) -> SpecimenCycleView {
        return SpecimenCycleView(
            code: item.code,
            name: item.name,
            ratio: String(format: "%.2f", item.ratio),
            country: Kit.Text.truncate(item.country, limit: 40),
            activeText: "\(item.active)",
            scoreText: String(format: "%.2f", item.score),
            currency: item.currency,
            amountText: String(format: "%.2f", item.amount),
            margin: String(format: "%.2f", item.margin),
            updatedAtText: String(item.updatedAt),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenCycleViews(_ items: [SpecimenCycle]) -> [SpecimenCycleView] {
        var views: [SpecimenCycleView] = []
        for item in items {
            views.append(toSpecimenCycleView(item))
        }
        return views
    }

    static func sumSpecimenCycleView(_ view: SpecimenCycleView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedRatio + parsedScore + parsedAmount
    }
}
