import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a lenient revocation bundle.
    final class LenientRevocationBundleView {
        var code: String
        var name: String
        var pinned: String
        var contactEmail: String
        var allergy: String
        var region: String
        var refills: String
        var statusLabel: String

        init(code: String, name: String, pinned: String, contactEmail: String, allergy: String, region: String, refills: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.contactEmail = contactEmail
            self.allergy = allergy
            self.region = region
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toLenientRevocationBundleView(_ item: LenientRevocationBundle) -> LenientRevocationBundleView {
        return LenientRevocationBundleView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            pinned: "\(item.pinned)",
            contactEmail: item.contactEmail,
            allergy: item.allergy,
            region: item.region,
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientRevocationBundleViews(_ items: [LenientRevocationBundle]) -> [LenientRevocationBundleView] {
        var views: [LenientRevocationBundleView] = []
        for item in items {
            views.append(toLenientRevocationBundleView(item))
        }
        return views
    }

    static func sumLenientRevocationBundleView(_ view: LenientRevocationBundleView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedRefills)
    }
}
