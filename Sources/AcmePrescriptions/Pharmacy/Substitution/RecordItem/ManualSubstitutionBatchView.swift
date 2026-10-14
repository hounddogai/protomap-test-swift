import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual substitution batch.
    final class ManualSubstitutionBatchView {
        var codeText: String
        var label: String
        var procedureCode: String
        var revisionText: String
        var approved: String
        var phoneText: String
        var discount: String
        var encounterID: String
        var endsAt: String
        var title: String
        var statusLabel: String

        init(codeText: String, label: String, procedureCode: String, revisionText: String, approved: String, phoneText: String, discount: String, encounterID: String, endsAt: String, title: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.procedureCode = procedureCode
            self.revisionText = revisionText
            self.approved = approved
            self.phoneText = phoneText
            self.discount = discount
            self.encounterID = encounterID
            self.endsAt = endsAt
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toManualSubstitutionBatchView(_ item: ManualSubstitutionBatch) -> ManualSubstitutionBatchView {
        return ManualSubstitutionBatchView(
            codeText: item.code,
            label: item.label,
            procedureCode: item.procedureCode,
            revisionText: String(item.revision),
            approved: "\(item.approved)",
            phoneText: item.phone,
            discount: String(format: "%.2f", item.discount),
            encounterID: item.encounterID,
            endsAt: String(item.endsAt),
            title: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualSubstitutionBatchViews(_ items: [ManualSubstitutionBatch]) -> [ManualSubstitutionBatchView] {
        var views: [ManualSubstitutionBatchView] = []
        for item in items {
            views.append(toManualSubstitutionBatchView(item))
        }
        return views
    }

    static func sumManualSubstitutionBatchView(_ view: ManualSubstitutionBatchView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedRevision) + parsedDiscount + Double(parsedEndsAt)
    }
}
