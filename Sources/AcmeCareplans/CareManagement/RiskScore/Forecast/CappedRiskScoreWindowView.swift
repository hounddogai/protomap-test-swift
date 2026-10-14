import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a capped risk score window.
    final class CappedRiskScoreWindowView {
        var code: String
        var title: String
        var description: String
        var endsAtText: String
        var amount: String
        var ratio: String
        var currencyText: String
        var budget: String
        var visitMinutesText: String
        var activeText: String
        var sequence: String
        var statusLabel: String

        init(code: String, title: String, description: String, endsAtText: String, amount: String, ratio: String, currencyText: String, budget: String, visitMinutesText: String, activeText: String, sequence: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.description = description
            self.endsAtText = endsAtText
            self.amount = amount
            self.ratio = ratio
            self.currencyText = currencyText
            self.budget = budget
            self.visitMinutesText = visitMinutesText
            self.activeText = activeText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toCappedRiskScoreWindowView(_ item: CappedRiskScoreWindow) -> CappedRiskScoreWindowView {
        return CappedRiskScoreWindowView(
            code: item.code,
            title: item.title,
            description: item.description,
            endsAtText: String(item.endsAt),
            amount: String(format: "%.2f", item.amount),
            ratio: String(format: "%.2f", item.ratio),
            currencyText: Kit.Text.truncate(item.currency, limit: 64),
            budget: String(format: "%.2f", item.budget),
            visitMinutesText: String(item.visitMinutes),
            activeText: "\(item.active)",
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedRiskScoreWindowViews(_ items: [CappedRiskScoreWindow]) -> [CappedRiskScoreWindowView] {
        var views: [CappedRiskScoreWindowView] = []
        for item in items {
            views.append(toCappedRiskScoreWindowView(item))
        }
        return views
    }

    static func sumCappedRiskScoreWindowView(_ view: CappedRiskScoreWindowView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedEndsAt) + parsedAmount + parsedRatio
    }
}
