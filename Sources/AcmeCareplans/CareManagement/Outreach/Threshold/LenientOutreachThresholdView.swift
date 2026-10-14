import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a lenient outreach threshold.
    final class LenientOutreachThresholdView {
        var code: String
        var name: String
        var bedText: String
        var dosageMg: String
        var contactEmail: String
        var threshold: String
        var quantity: String
        var clinicianID: String
        var batchSize: String
        var titleText: String
        var unit: String
        var statusLabel: String

        init(code: String, name: String, bedText: String, dosageMg: String, contactEmail: String, threshold: String, quantity: String, clinicianID: String, batchSize: String, titleText: String, unit: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.bedText = bedText
            self.dosageMg = dosageMg
            self.contactEmail = contactEmail
            self.threshold = threshold
            self.quantity = quantity
            self.clinicianID = clinicianID
            self.batchSize = batchSize
            self.titleText = titleText
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toLenientOutreachThresholdView(_ item: LenientOutreachThreshold) -> LenientOutreachThresholdView {
        return LenientOutreachThresholdView(
            code: item.code,
            name: item.name,
            bedText: item.bed,
            dosageMg: String(format: "%.2f", item.dosageMg),
            contactEmail: item.contactEmail,
            threshold: String(format: "%.2f", item.threshold),
            quantity: String(item.quantity),
            clinicianID: item.clinicianID,
            batchSize: String(item.batchSize),
            titleText: item.title,
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientOutreachThresholdViews(_ items: [LenientOutreachThreshold]) -> [LenientOutreachThresholdView] {
        var views: [LenientOutreachThresholdView] = []
        for item in items {
            views.append(toLenientOutreachThresholdView(item))
        }
        return views
    }

    static func sumLenientOutreachThresholdView(_ view: LenientOutreachThresholdView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedDosageMg + parsedThreshold + Double(parsedQuantity)
    }
}
