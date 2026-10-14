import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary slot.
    final class FormularySlotView {
        var code: String
        var title: String
        var externalRefText: String
        var phone: String
        var source: String
        var category: String
        var batchSizeText: String
        var startsAt: String
        var statusLabel: String

        init(code: String, title: String, externalRefText: String, phone: String, source: String, category: String, batchSizeText: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.externalRefText = externalRefText
            self.phone = phone
            self.source = source
            self.category = category
            self.batchSizeText = batchSizeText
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toFormularySlotView(_ item: FormularySlot) -> FormularySlotView {
        return FormularySlotView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 120),
            phone: item.phone,
            source: item.source,
            category: Kit.Text.truncate(item.category, limit: 64),
            batchSizeText: String(item.batchSize),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularySlotViews(_ items: [FormularySlot]) -> [FormularySlotView] {
        var views: [FormularySlotView] = []
        for item in items {
            views.append(toFormularySlotView(item))
        }
        return views
    }

    static func sumFormularySlotView(_ view: FormularySlotView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedStartsAt)
    }
}
