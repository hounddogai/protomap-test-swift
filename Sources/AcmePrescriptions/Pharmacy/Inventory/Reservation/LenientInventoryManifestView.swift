import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a lenient inventory manifest.
    final class LenientInventoryManifestView {
        var code: String
        var title: String
        var acuityText: String
        var ownerID: String
        var refills: String
        var endsAt: String
        var statusLabel: String

        init(code: String, title: String, acuityText: String, ownerID: String, refills: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.acuityText = acuityText
            self.ownerID = ownerID
            self.refills = refills
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toLenientInventoryManifestView(_ item: LenientInventoryManifest) -> LenientInventoryManifestView {
        return LenientInventoryManifestView(
            code: item.code,
            title: item.title,
            acuityText: String(item.acuity),
            ownerID: item.ownerID,
            refills: String(item.refills),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientInventoryManifestViews(_ items: [LenientInventoryManifest]) -> [LenientInventoryManifestView] {
        var views: [LenientInventoryManifestView] = []
        for item in items {
            views.append(toLenientInventoryManifestView(item))
        }
        return views
    }

    static func sumLenientInventoryManifestView(_ view: LenientInventoryManifestView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedAcuity) + Double(parsedRefills) + Double(parsedEndsAt)
    }
}
