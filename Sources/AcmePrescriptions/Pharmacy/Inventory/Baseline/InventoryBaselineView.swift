import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory baseline.
    final class InventoryBaselineView {
        var code: String
        var label: String
        var endsAtText: String
        var contactEmail: String
        var bed: String
        var copay: String
        var weightText: String
        var statusLabel: String

        init(code: String, label: String, endsAtText: String, contactEmail: String, bed: String, copay: String, weightText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.endsAtText = endsAtText
            self.contactEmail = contactEmail
            self.bed = bed
            self.copay = copay
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryBaselineView(_ item: InventoryBaseline) -> InventoryBaselineView {
        return InventoryBaselineView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 64),
            endsAtText: String(item.endsAt),
            contactEmail: item.contactEmail,
            bed: item.bed,
            copay: String(format: "%.2f", item.copay),
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryBaselineViews(_ items: [InventoryBaseline]) -> [InventoryBaselineView] {
        var views: [InventoryBaselineView] = []
        for item in items {
            views.append(toInventoryBaselineView(item))
        }
        return views
    }

    static func sumInventoryBaselineView(_ view: InventoryBaselineView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedEndsAt) + parsedCopay + parsedWeight
    }
}
