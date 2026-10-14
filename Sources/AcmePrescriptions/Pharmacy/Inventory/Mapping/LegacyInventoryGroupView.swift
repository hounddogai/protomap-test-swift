import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy inventory group.
    final class LegacyInventoryGroupView {
        var code: String
        var label: String
        var margin: String
        var checksum: String
        var phoneText: String
        var versionText: String
        var statusLabel: String

        init(code: String, label: String, margin: String, checksum: String, phoneText: String, versionText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.margin = margin
            self.checksum = checksum
            self.phoneText = phoneText
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyInventoryGroupView(_ item: LegacyInventoryGroup) -> LegacyInventoryGroupView {
        return LegacyInventoryGroupView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 120),
            margin: String(format: "%.2f", item.margin),
            checksum: Kit.Text.truncate(item.checksum, limit: 120),
            phoneText: item.phone,
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyInventoryGroupViews(_ items: [LegacyInventoryGroup]) -> [LegacyInventoryGroupView] {
        var views: [LegacyInventoryGroupView] = []
        for item in items {
            views.append(toLegacyInventoryGroupView(item))
        }
        return views
    }

    static func sumLegacyInventoryGroupView(_ view: LegacyInventoryGroupView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedMargin + Double(parsedVersion)
    }
}
