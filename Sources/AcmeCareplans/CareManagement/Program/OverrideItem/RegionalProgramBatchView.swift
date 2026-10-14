import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a regional program batch.
    final class RegionalProgramBatchView {
        var code: String
        var label: String
        var contactEmail: String
        var discount: String
        var summary: String
        var ownerID: String
        var pinned: String
        var acuityText: String
        var statusLabel: String

        init(code: String, label: String, contactEmail: String, discount: String, summary: String, ownerID: String, pinned: String, acuityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.discount = discount
            self.summary = summary
            self.ownerID = ownerID
            self.pinned = pinned
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalProgramBatchView(_ item: RegionalProgramBatch) -> RegionalProgramBatchView {
        return RegionalProgramBatchView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            contactEmail: item.contactEmail,
            discount: String(format: "%.2f", item.discount),
            summary: Kit.Text.truncate(item.summary, limit: 40),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            pinned: "\(item.pinned)",
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalProgramBatchViews(_ items: [RegionalProgramBatch]) -> [RegionalProgramBatchView] {
        var views: [RegionalProgramBatchView] = []
        for item in items {
            views.append(toRegionalProgramBatchView(item))
        }
        return views
    }

    static func sumRegionalProgramBatchView(_ view: RegionalProgramBatchView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedDiscount + Double(parsedAcuity)
    }
}
