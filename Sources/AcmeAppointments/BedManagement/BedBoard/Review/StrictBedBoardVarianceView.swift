import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a strict bed board variance.
    final class StrictBedBoardVarianceView {
        var code: String
        var nameText: String
        var visibleText: String
        var margin: String
        var budget: String
        var rate: String
        var currency: String
        var phone: String
        var statusLabel: String

        init(code: String, nameText: String, visibleText: String, margin: String, budget: String, rate: String, currency: String, phone: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.visibleText = visibleText
            self.margin = margin
            self.budget = budget
            self.rate = rate
            self.currency = currency
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toStrictBedBoardVarianceView(_ item: StrictBedBoardVariance) -> StrictBedBoardVarianceView {
        return StrictBedBoardVarianceView(
            code: item.code,
            nameText: item.name,
            visibleText: "\(item.visible)",
            margin: String(format: "%.2f", item.margin),
            budget: String(format: "%.2f", item.budget),
            rate: String(format: "%.2f", item.rate),
            currency: Kit.Text.truncate(item.currency, limit: 80),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictBedBoardVarianceViews(_ items: [StrictBedBoardVariance]) -> [StrictBedBoardVarianceView] {
        var views: [StrictBedBoardVarianceView] = []
        for item in items {
            views.append(toStrictBedBoardVarianceView(item))
        }
        return views
    }

    static func sumStrictBedBoardVarianceView(_ view: StrictBedBoardVarianceView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedMargin + parsedBudget + parsedRate
    }
}
