import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a capped formulary draft.
    final class CappedFormularyDraftView {
        var code: String
        var label: String
        var maximum: String
        var discount: String
        var activeText: String
        var copayText: String
        var revision: String
        var facility: String
        var refills: String
        var patientRef: String
        var statusLabel: String

        init(code: String, label: String, maximum: String, discount: String, activeText: String, copayText: String, revision: String, facility: String, refills: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.discount = discount
            self.activeText = activeText
            self.copayText = copayText
            self.revision = revision
            self.facility = facility
            self.refills = refills
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toCappedFormularyDraftView(_ item: CappedFormularyDraft) -> CappedFormularyDraftView {
        return CappedFormularyDraftView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            maximum: String(format: "%.2f", item.maximum),
            discount: String(format: "%.2f", item.discount),
            activeText: "\(item.active)",
            copayText: String(format: "%.2f", item.copay),
            revision: String(item.revision),
            facility: item.facility,
            refills: String(item.refills),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedFormularyDraftViews(_ items: [CappedFormularyDraft]) -> [CappedFormularyDraftView] {
        var views: [CappedFormularyDraftView] = []
        for item in items {
            views.append(toCappedFormularyDraftView(item))
        }
        return views
    }

    static func sumCappedFormularyDraftView(_ view: CappedFormularyDraftView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedMaximum + parsedDiscount + parsedCopay
    }
}
