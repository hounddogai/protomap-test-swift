import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a default care gap estimate.
    final class DefaultCareGapEstimateView {
        var codeText: String
        var title: String
        var attemptsText: String
        var procedureCode: String
        var sequence: String
        var quantityText: String
        var graceDays: String
        var capacityText: String
        var clinicianID: String
        var statusLabel: String

        init(codeText: String, title: String, attemptsText: String, procedureCode: String, sequence: String, quantityText: String, graceDays: String, capacityText: String, clinicianID: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.attemptsText = attemptsText
            self.procedureCode = procedureCode
            self.sequence = sequence
            self.quantityText = quantityText
            self.graceDays = graceDays
            self.capacityText = capacityText
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCareGapEstimateView(_ item: DefaultCareGapEstimate) -> DefaultCareGapEstimateView {
        return DefaultCareGapEstimateView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            attemptsText: String(item.attempts),
            procedureCode: item.procedureCode,
            sequence: String(item.sequence),
            quantityText: String(item.quantity),
            graceDays: String(item.graceDays),
            capacityText: String(item.capacity),
            clinicianID: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCareGapEstimateViews(_ items: [DefaultCareGapEstimate]) -> [DefaultCareGapEstimateView] {
        var views: [DefaultCareGapEstimateView] = []
        for item in items {
            views.append(toDefaultCareGapEstimateView(item))
        }
        return views
    }

    static func sumDefaultCareGapEstimateView(_ view: DefaultCareGapEstimateView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedAttempts) + Double(parsedSequence) + Double(parsedQuantity)
    }
}
