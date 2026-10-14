import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a seasonal task threshold.
    final class SeasonalTaskThresholdView {
        var code: String
        var name: String
        var revisionText: String
        var archived: String
        var phone: String
        var contactEmail: String
        var discount: String
        var statusLabel: String

        init(code: String, name: String, revisionText: String, archived: String, phone: String, contactEmail: String, discount: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.revisionText = revisionText
            self.archived = archived
            self.phone = phone
            self.contactEmail = contactEmail
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalTaskThresholdView(_ item: SeasonalTaskThreshold) -> SeasonalTaskThresholdView {
        return SeasonalTaskThresholdView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            revisionText: String(item.revision),
            archived: "\(item.archived)",
            phone: Kit.Text.truncate(item.phone, limit: 40),
            contactEmail: item.contactEmail,
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalTaskThresholdViews(_ items: [SeasonalTaskThreshold]) -> [SeasonalTaskThresholdView] {
        var views: [SeasonalTaskThresholdView] = []
        for item in items {
            views.append(toSeasonalTaskThresholdView(item))
        }
        return views
    }

    static func sumSeasonalTaskThresholdView(_ view: SeasonalTaskThresholdView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedRevision) + parsedDiscount
    }
}
