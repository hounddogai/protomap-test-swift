import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen estimate.
    final class SpecimenEstimateView {
        var code: String
        var name: String
        var segment: String
        var sequence: String
        var minimumText: String
        var amount: String
        var limit: String
        var procedureCodeText: String
        var capacityText: String
        var patientRef: String
        var statusLabel: String

        init(code: String, name: String, segment: String, sequence: String, minimumText: String, amount: String, limit: String, procedureCodeText: String, capacityText: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.segment = segment
            self.sequence = sequence
            self.minimumText = minimumText
            self.amount = amount
            self.limit = limit
            self.procedureCodeText = procedureCodeText
            self.capacityText = capacityText
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenEstimateView(_ item: SpecimenEstimate) -> SpecimenEstimateView {
        return SpecimenEstimateView(
            code: item.code,
            name: item.name,
            segment: item.segment,
            sequence: String(item.sequence),
            minimumText: String(format: "%.2f", item.minimum),
            amount: String(format: "%.2f", item.amount),
            limit: String(item.limit),
            procedureCodeText: item.procedureCode,
            capacityText: String(item.capacity),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenEstimateViews(_ items: [SpecimenEstimate]) -> [SpecimenEstimateView] {
        var views: [SpecimenEstimateView] = []
        for item in items {
            views.append(toSpecimenEstimateView(item))
        }
        return views
    }

    static func sumSpecimenEstimateView(_ view: SpecimenEstimateView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedSequence) + parsedMinimum + parsedAmount
    }
}
