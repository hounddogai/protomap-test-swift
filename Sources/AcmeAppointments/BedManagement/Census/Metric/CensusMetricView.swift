import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census metric.
    final class CensusMetricView {
        var code: String
        var name: String
        var facility: String
        var quantity: String
        var reviewerText: String
        var source: String
        var amountText: String
        var sequence: String
        var statusLabel: String

        init(code: String, name: String, facility: String, quantity: String, reviewerText: String, source: String, amountText: String, sequence: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.facility = facility
            self.quantity = quantity
            self.reviewerText = reviewerText
            self.source = source
            self.amountText = amountText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toCensusMetricView(_ item: CensusMetric) -> CensusMetricView {
        return CensusMetricView(
            code: item.code,
            name: item.name,
            facility: item.facility,
            quantity: String(item.quantity),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 80),
            source: item.source,
            amountText: String(format: "%.2f", item.amount),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusMetricViews(_ items: [CensusMetric]) -> [CensusMetricView] {
        var views: [CensusMetricView] = []
        for item in items {
            views.append(toCensusMetricView(item))
        }
        return views
    }

    static func sumCensusMetricView(_ view: CensusMetricView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedQuantity) + parsedAmount + Double(parsedSequence)
    }
}
