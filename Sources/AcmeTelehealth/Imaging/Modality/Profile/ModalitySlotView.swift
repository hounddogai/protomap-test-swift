import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality slot.
    final class ModalitySlotView {
        var codeText: String
        var label: String
        var acuity: String
        var discount: String
        var revisionText: String
        var nameText: String
        var ceiling: String
        var weight: String
        var versionText: String
        var amountText: String
        var externalRefText: String
        var statusLabel: String

        init(codeText: String, label: String, acuity: String, discount: String, revisionText: String, nameText: String, ceiling: String, weight: String, versionText: String, amountText: String, externalRefText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.acuity = acuity
            self.discount = discount
            self.revisionText = revisionText
            self.nameText = nameText
            self.ceiling = ceiling
            self.weight = weight
            self.versionText = versionText
            self.amountText = amountText
            self.externalRefText = externalRefText
            self.statusLabel = statusLabel
        }
    }

    static func toModalitySlotView(_ item: ModalitySlot) -> ModalitySlotView {
        return ModalitySlotView(
            codeText: item.code,
            label: item.label,
            acuity: String(item.acuity),
            discount: String(format: "%.2f", item.discount),
            revisionText: String(item.revision),
            nameText: Kit.Text.truncate(item.name, limit: 120),
            ceiling: String(format: "%.2f", item.ceiling),
            weight: String(format: "%.2f", item.weight),
            versionText: String(item.version),
            amountText: String(format: "%.2f", item.amount),
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalitySlotViews(_ items: [ModalitySlot]) -> [ModalitySlotView] {
        var views: [ModalitySlotView] = []
        for item in items {
            views.append(toModalitySlotView(item))
        }
        return views
    }

    static func sumModalitySlotView(_ view: ModalitySlotView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedAcuity) + parsedDiscount + Double(parsedRevision)
    }
}
