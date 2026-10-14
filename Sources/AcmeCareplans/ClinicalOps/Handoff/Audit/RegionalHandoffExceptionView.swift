import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a regional handoff exception.
    final class RegionalHandoffExceptionView {
        var codeText: String
        var name: String
        var batchSizeText: String
        var quantity: String
        var patientRef: String
        var endsAt: String
        var statusLabel: String

        init(codeText: String, name: String, batchSizeText: String, quantity: String, patientRef: String, endsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.batchSizeText = batchSizeText
            self.quantity = quantity
            self.patientRef = patientRef
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalHandoffExceptionView(_ item: RegionalHandoffException) -> RegionalHandoffExceptionView {
        return RegionalHandoffExceptionView(
            codeText: item.code,
            name: item.name,
            batchSizeText: String(item.batchSize),
            quantity: String(item.quantity),
            patientRef: item.patientRef,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalHandoffExceptionViews(_ items: [RegionalHandoffException]) -> [RegionalHandoffExceptionView] {
        var views: [RegionalHandoffExceptionView] = []
        for item in items {
            views.append(toRegionalHandoffExceptionView(item))
        }
        return views
    }

    static func sumRegionalHandoffExceptionView(_ view: RegionalHandoffExceptionView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedQuantity) + Double(parsedEndsAt)
    }
}
