import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered denial checkpoint.
    final class TieredDenialCheckpointView {
        var code: String
        var label: String
        var refills: String
        var versionText: String
        var encounterID: String
        var facility: String
        var statusLabel: String

        init(code: String, label: String, refills: String, versionText: String, encounterID: String, facility: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.refills = refills
            self.versionText = versionText
            self.encounterID = encounterID
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toTieredDenialCheckpointView(_ item: TieredDenialCheckpoint) -> TieredDenialCheckpointView {
        return TieredDenialCheckpointView(
            code: item.code,
            label: item.label,
            refills: String(item.refills),
            versionText: String(item.version),
            encounterID: item.encounterID,
            facility: Kit.Text.truncate(item.facility, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredDenialCheckpointViews(_ items: [TieredDenialCheckpoint]) -> [TieredDenialCheckpointView] {
        var views: [TieredDenialCheckpointView] = []
        for item in items {
            views.append(toTieredDenialCheckpointView(item))
        }
        return views
    }

    static func sumTieredDenialCheckpointView(_ view: TieredDenialCheckpointView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedRefills) + Double(parsedVersion)
    }
}
