import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set batch.
    final class OrderSetBatchView {
        var code: String
        var name: String
        var bed: String
        var copay: String
        var clinicianIDText: String
        var allergy: String
        var statusLabel: String

        init(code: String, name: String, bed: String, copay: String, clinicianIDText: String, allergy: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.bed = bed
            self.copay = copay
            self.clinicianIDText = clinicianIDText
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetBatchView(_ item: OrderSetBatch) -> OrderSetBatchView {
        return OrderSetBatchView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            bed: item.bed,
            copay: String(format: "%.2f", item.copay),
            clinicianIDText: item.clinicianID,
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetBatchViews(_ items: [OrderSetBatch]) -> [OrderSetBatchView] {
        var views: [OrderSetBatchView] = []
        for item in items {
            views.append(toOrderSetBatchView(item))
        }
        return views
    }

    static func sumOrderSetBatchView(_ view: OrderSetBatchView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
