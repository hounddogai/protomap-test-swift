import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a rolling shift manifest.
    final class RollingShiftManifestView {
        var code: String
        var nameText: String
        var revisionText: String
        var amountText: String
        var threshold: String
        var ownerIDText: String
        var region: String
        var versionText: String
        var floorValue: String
        var segment: String
        var endsAt: String
        var statusLabel: String

        init(code: String, nameText: String, revisionText: String, amountText: String, threshold: String, ownerIDText: String, region: String, versionText: String, floorValue: String, segment: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.revisionText = revisionText
            self.amountText = amountText
            self.threshold = threshold
            self.ownerIDText = ownerIDText
            self.region = region
            self.versionText = versionText
            self.floorValue = floorValue
            self.segment = segment
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toRollingShiftManifestView(_ item: RollingShiftManifest) -> RollingShiftManifestView {
        return RollingShiftManifestView(
            code: item.code,
            nameText: item.name,
            revisionText: String(item.revision),
            amountText: String(format: "%.2f", item.amount),
            threshold: String(format: "%.2f", item.threshold),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 120),
            region: item.region,
            versionText: String(item.version),
            floorValue: String(format: "%.2f", item.floorValue),
            segment: item.segment,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingShiftManifestViews(_ items: [RollingShiftManifest]) -> [RollingShiftManifestView] {
        var views: [RollingShiftManifestView] = []
        for item in items {
            views.append(toRollingShiftManifestView(item))
        }
        return views
    }

    static func sumRollingShiftManifestView(_ view: RollingShiftManifestView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedRevision) + parsedAmount + parsedThreshold
    }
}
