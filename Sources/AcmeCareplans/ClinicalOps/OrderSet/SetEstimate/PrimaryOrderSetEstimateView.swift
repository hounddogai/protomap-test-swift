import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary order set estimate.
    final class PrimaryOrderSetEstimateView {
        var codeText: String
        var title: String
        var contactEmailText: String
        var limit: String
        var amount: String
        var patientRefText: String
        var capacityText: String
        var diagnosisCode: String
        var channel: String
        var maximum: String
        var visitMinutesText: String
        var statusLabel: String

        init(codeText: String, title: String, contactEmailText: String, limit: String, amount: String, patientRefText: String, capacityText: String, diagnosisCode: String, channel: String, maximum: String, visitMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.contactEmailText = contactEmailText
            self.limit = limit
            self.amount = amount
            self.patientRefText = patientRefText
            self.capacityText = capacityText
            self.diagnosisCode = diagnosisCode
            self.channel = channel
            self.maximum = maximum
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryOrderSetEstimateView(_ item: PrimaryOrderSetEstimate) -> PrimaryOrderSetEstimateView {
        return PrimaryOrderSetEstimateView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            contactEmailText: item.contactEmail,
            limit: String(item.limit),
            amount: String(format: "%.2f", item.amount),
            patientRefText: item.patientRef,
            capacityText: String(item.capacity),
            diagnosisCode: item.diagnosisCode,
            channel: item.channel,
            maximum: String(format: "%.2f", item.maximum),
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryOrderSetEstimateViews(_ items: [PrimaryOrderSetEstimate]) -> [PrimaryOrderSetEstimateView] {
        var views: [PrimaryOrderSetEstimateView] = []
        for item in items {
            views.append(toPrimaryOrderSetEstimateView(item))
        }
        return views
    }

    static func sumPrimaryOrderSetEstimateView(_ view: PrimaryOrderSetEstimateView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedLimit) + parsedAmount + Double(parsedCapacity)
    }
}
