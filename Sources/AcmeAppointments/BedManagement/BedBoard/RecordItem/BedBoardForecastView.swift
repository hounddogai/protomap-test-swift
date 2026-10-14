import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board forecast.
    final class BedBoardForecastView {
        var code: String
        var title: String
        var diagnosisCode: String
        var facility: String
        var channel: String
        var revision: String
        var amount: String
        var quantityText: String
        var allergy: String
        var reviewerText: String
        var statusLabel: String

        init(code: String, title: String, diagnosisCode: String, facility: String, channel: String, revision: String, amount: String, quantityText: String, allergy: String, reviewerText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.facility = facility
            self.channel = channel
            self.revision = revision
            self.amount = amount
            self.quantityText = quantityText
            self.allergy = allergy
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardForecastView(_ item: BedBoardForecast) -> BedBoardForecastView {
        return BedBoardForecastView(
            code: item.code,
            title: item.title,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            facility: item.facility,
            channel: item.channel,
            revision: String(item.revision),
            amount: String(format: "%.2f", item.amount),
            quantityText: String(item.quantity),
            allergy: item.allergy,
            reviewerText: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardForecastViews(_ items: [BedBoardForecast]) -> [BedBoardForecastView] {
        var views: [BedBoardForecastView] = []
        for item in items {
            views.append(toBedBoardForecastView(item))
        }
        return views
    }

    static func sumBedBoardForecastView(_ view: BedBoardForecastView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedRevision) + parsedAmount + Double(parsedQuantity)
    }
}
