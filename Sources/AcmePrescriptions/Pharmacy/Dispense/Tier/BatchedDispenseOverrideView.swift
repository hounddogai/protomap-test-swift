import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a batched dispense override.
    final class BatchedDispenseOverrideView {
        var code: String
        var name: String
        var notes: String
        var costText: String
        var dosageMg: String
        var versionText: String
        var statusLabel: String

        init(code: String, name: String, notes: String, costText: String, dosageMg: String, versionText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.notes = notes
            self.costText = costText
            self.dosageMg = dosageMg
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedDispenseOverrideView(_ item: BatchedDispenseOverride) -> BatchedDispenseOverrideView {
        return BatchedDispenseOverrideView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            notes: item.notes,
            costText: String(format: "%.2f", item.cost),
            dosageMg: String(format: "%.2f", item.dosageMg),
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedDispenseOverrideViews(_ items: [BatchedDispenseOverride]) -> [BatchedDispenseOverrideView] {
        var views: [BatchedDispenseOverrideView] = []
        for item in items {
            views.append(toBatchedDispenseOverrideView(item))
        }
        return views
    }

    static func sumBatchedDispenseOverrideView(_ view: BatchedDispenseOverrideView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedCost + parsedDosageMg + Double(parsedVersion)
    }
}
