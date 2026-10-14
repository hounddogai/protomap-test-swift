import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory entry.
    final class InventoryEntryView {
        var code: String
        var labelText: String
        var category: String
        var clinicianID: String
        var notes: String
        var budgetText: String
        var ownerIDText: String
        var ratio: String
        var refills: String
        var statusLabel: String

        init(code: String, labelText: String, category: String, clinicianID: String, notes: String, budgetText: String, ownerIDText: String, ratio: String, refills: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.category = category
            self.clinicianID = clinicianID
            self.notes = notes
            self.budgetText = budgetText
            self.ownerIDText = ownerIDText
            self.ratio = ratio
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryEntryView(_ item: InventoryEntry) -> InventoryEntryView {
        return InventoryEntryView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            category: Kit.Text.truncate(item.category, limit: 120),
            clinicianID: item.clinicianID,
            notes: item.notes,
            budgetText: String(format: "%.2f", item.budget),
            ownerIDText: item.ownerID,
            ratio: String(format: "%.2f", item.ratio),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryEntryViews(_ items: [InventoryEntry]) -> [InventoryEntryView] {
        var views: [InventoryEntryView] = []
        for item in items {
            views.append(toInventoryEntryView(item))
        }
        return views
    }

    static func sumInventoryEntryView(_ view: InventoryEntryView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedBudget + parsedRatio + Double(parsedRefills)
    }
}
