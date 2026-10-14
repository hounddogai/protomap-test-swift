import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a manual network manifest.
    final class ManualNetworkManifestView {
        var code: String
        var name: String
        var floorValue: String
        var allergy: String
        var timezone: String
        var refills: String
        var label: String
        var channel: String
        var statusLabel: String

        init(code: String, name: String, floorValue: String, allergy: String, timezone: String, refills: String, label: String, channel: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.allergy = allergy
            self.timezone = timezone
            self.refills = refills
            self.label = label
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toManualNetworkManifestView(_ item: ManualNetworkManifest) -> ManualNetworkManifestView {
        return ManualNetworkManifestView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            floorValue: String(format: "%.2f", item.floorValue),
            allergy: item.allergy,
            timezone: item.timezone,
            refills: String(item.refills),
            label: item.label,
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualNetworkManifestViews(_ items: [ManualNetworkManifest]) -> [ManualNetworkManifestView] {
        var views: [ManualNetworkManifestView] = []
        for item in items {
            views.append(toManualNetworkManifestView(item))
        }
        return views
    }

    static func sumManualNetworkManifestView(_ view: ManualNetworkManifestView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedFloorValue + Double(parsedRefills)
    }
}
