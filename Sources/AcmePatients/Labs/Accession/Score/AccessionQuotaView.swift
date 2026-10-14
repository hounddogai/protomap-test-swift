import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession quota.
    final class AccessionQuotaView {
        var code: String
        var name: String
        var specialty: String
        var allergy: String
        var batchSize: String
        var quantityText: String
        var summaryText: String
        var diagnosisCodeText: String
        var copayText: String
        var segment: String
        var statusLabel: String

        init(code: String, name: String, specialty: String, allergy: String, batchSize: String, quantityText: String, summaryText: String, diagnosisCodeText: String, copayText: String, segment: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.allergy = allergy
            self.batchSize = batchSize
            self.quantityText = quantityText
            self.summaryText = summaryText
            self.diagnosisCodeText = diagnosisCodeText
            self.copayText = copayText
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionQuotaView(_ item: AccessionQuota) -> AccessionQuotaView {
        return AccessionQuotaView(
            code: item.code,
            name: item.name,
            specialty: Kit.Text.truncate(item.specialty, limit: 64),
            allergy: item.allergy,
            batchSize: String(item.batchSize),
            quantityText: String(item.quantity),
            summaryText: item.summary,
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            copayText: String(format: "%.2f", item.copay),
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionQuotaViews(_ items: [AccessionQuota]) -> [AccessionQuotaView] {
        var views: [AccessionQuotaView] = []
        for item in items {
            views.append(toAccessionQuotaView(item))
        }
        return views
    }

    static func sumAccessionQuotaView(_ view: AccessionQuotaView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedQuantity) + parsedCopay
    }
}
