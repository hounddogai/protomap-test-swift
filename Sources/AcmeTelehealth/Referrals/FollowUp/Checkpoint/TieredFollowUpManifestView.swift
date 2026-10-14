import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a tiered follow up manifest.
    final class TieredFollowUpManifestView {
        var code: String
        var label: String
        var approved: String
        var contactEmailText: String
        var discount: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, label: String, approved: String, contactEmailText: String, discount: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.approved = approved
            self.contactEmailText = contactEmailText
            self.discount = discount
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toTieredFollowUpManifestView(_ item: TieredFollowUpManifest) -> TieredFollowUpManifestView {
        return TieredFollowUpManifestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            approved: "\(item.approved)",
            contactEmailText: item.contactEmail,
            discount: String(format: "%.2f", item.discount),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredFollowUpManifestViews(_ items: [TieredFollowUpManifest]) -> [TieredFollowUpManifestView] {
        var views: [TieredFollowUpManifestView] = []
        for item in items {
            views.append(toTieredFollowUpManifestView(item))
        }
        return views
    }

    static func sumTieredFollowUpManifestView(_ view: TieredFollowUpManifestView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDiscount + parsedDosageMg
    }
}
