import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality allocation.
    final class ModalityAllocationView {
        var code: String
        var label: String
        var locale: String
        var visible: String
        var endsAtText: String
        var category: String
        var batchSize: String
        var encounterID: String
        var phone: String
        var budgetText: String
        var statusLabel: String

        init(code: String, label: String, locale: String, visible: String, endsAtText: String, category: String, batchSize: String, encounterID: String, phone: String, budgetText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.locale = locale
            self.visible = visible
            self.endsAtText = endsAtText
            self.category = category
            self.batchSize = batchSize
            self.encounterID = encounterID
            self.phone = phone
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toModalityAllocationView(_ item: ModalityAllocation) -> ModalityAllocationView {
        return ModalityAllocationView(
            code: item.code,
            label: item.label,
            locale: Kit.Text.truncate(item.locale, limit: 64),
            visible: "\(item.visible)",
            endsAtText: String(item.endsAt),
            category: item.category,
            batchSize: String(item.batchSize),
            encounterID: item.encounterID,
            phone: item.phone,
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityAllocationViews(_ items: [ModalityAllocation]) -> [ModalityAllocationView] {
        var views: [ModalityAllocationView] = []
        for item in items {
            views.append(toModalityAllocationView(item))
        }
        return views
    }

    static func sumModalityAllocationView(_ view: ModalityAllocationView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedBatchSize) + parsedBudget
    }
}
