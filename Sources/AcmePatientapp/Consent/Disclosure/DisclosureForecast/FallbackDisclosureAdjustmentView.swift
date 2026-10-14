import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a fallback disclosure adjustment.
    final class FallbackDisclosureAdjustmentView {
        var code: String
        var name: String
        var priority: String
        var batchSize: String
        var phone: String
        var dosageMg: String
        var region: String
        var patientRef: String
        var cost: String
        var revision: String
        var statusLabel: String

        init(code: String, name: String, priority: String, batchSize: String, phone: String, dosageMg: String, region: String, patientRef: String, cost: String, revision: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.priority = priority
            self.batchSize = batchSize
            self.phone = phone
            self.dosageMg = dosageMg
            self.region = region
            self.patientRef = patientRef
            self.cost = cost
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackDisclosureAdjustmentView(_ item: FallbackDisclosureAdjustment) -> FallbackDisclosureAdjustmentView {
        return FallbackDisclosureAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            priority: String(item.priority),
            batchSize: String(item.batchSize),
            phone: item.phone,
            dosageMg: String(format: "%.2f", item.dosageMg),
            region: Kit.Text.truncate(item.region, limit: 80),
            patientRef: item.patientRef,
            cost: String(format: "%.2f", item.cost),
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackDisclosureAdjustmentViews(_ items: [FallbackDisclosureAdjustment]) -> [FallbackDisclosureAdjustmentView] {
        var views: [FallbackDisclosureAdjustmentView] = []
        for item in items {
            views.append(toFallbackDisclosureAdjustmentView(item))
        }
        return views
    }

    static func sumFallbackDisclosureAdjustmentView(_ view: FallbackDisclosureAdjustmentView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedPriority) + Double(parsedBatchSize) + parsedDosageMg
    }
}
