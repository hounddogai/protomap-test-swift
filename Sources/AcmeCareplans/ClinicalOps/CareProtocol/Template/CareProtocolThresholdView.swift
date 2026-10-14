import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol threshold.
    final class CareProtocolThresholdView {
        var code: String
        var title: String
        var label: String
        var amount: String
        var dosageMg: String
        var rate: String
        var notes: String
        var statusLabel: String

        init(code: String, title: String, label: String, amount: String, dosageMg: String, rate: String, notes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.label = label
            self.amount = amount
            self.dosageMg = dosageMg
            self.rate = rate
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolThresholdView(_ item: CareProtocolThreshold) -> CareProtocolThresholdView {
        return CareProtocolThresholdView(
            code: item.code,
            title: item.title,
            label: item.label,
            amount: String(format: "%.2f", item.amount),
            dosageMg: String(format: "%.2f", item.dosageMg),
            rate: String(format: "%.2f", item.rate),
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolThresholdViews(_ items: [CareProtocolThreshold]) -> [CareProtocolThresholdView] {
        var views: [CareProtocolThresholdView] = []
        for item in items {
            views.append(toCareProtocolThresholdView(item))
        }
        return views
    }

    static func sumCareProtocolThresholdView(_ view: CareProtocolThresholdView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedAmount + parsedDosageMg + parsedRate
    }
}
