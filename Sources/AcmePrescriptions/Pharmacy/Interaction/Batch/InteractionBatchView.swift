import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction batch.
    final class InteractionBatchView {
        var code: String
        var name: String
        var ward: String
        var summary: String
        var dosageMg: String
        var payerText: String
        var statusLabel: String

        init(code: String, name: String, ward: String, summary: String, dosageMg: String, payerText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ward = ward
            self.summary = summary
            self.dosageMg = dosageMg
            self.payerText = payerText
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionBatchView(_ item: InteractionBatch) -> InteractionBatchView {
        return InteractionBatchView(
            code: item.code,
            name: item.name,
            ward: item.ward,
            summary: item.summary,
            dosageMg: String(format: "%.2f", item.dosageMg),
            payerText: Kit.Text.truncate(item.payer, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionBatchViews(_ items: [InteractionBatch]) -> [InteractionBatchView] {
        var views: [InteractionBatchView] = []
        for item in items {
            views.append(toInteractionBatchView(item))
        }
        return views
    }

    static func sumInteractionBatchView(_ view: InteractionBatchView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
