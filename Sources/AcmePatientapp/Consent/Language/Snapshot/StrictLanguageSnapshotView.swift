import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a strict language snapshot.
    final class StrictLanguageSnapshotView {
        var code: String
        var label: String
        var ceiling: String
        var activeText: String
        var allergyText: String
        var segment: String
        var channel: String
        var facilityText: String
        var category: String
        var statusLabel: String

        init(code: String, label: String, ceiling: String, activeText: String, allergyText: String, segment: String, channel: String, facilityText: String, category: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.activeText = activeText
            self.allergyText = allergyText
            self.segment = segment
            self.channel = channel
            self.facilityText = facilityText
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toStrictLanguageSnapshotView(_ item: StrictLanguageSnapshot) -> StrictLanguageSnapshotView {
        return StrictLanguageSnapshotView(
            code: item.code,
            label: item.label,
            ceiling: String(format: "%.2f", item.ceiling),
            activeText: "\(item.active)",
            allergyText: Kit.Text.truncate(item.allergy, limit: 40),
            segment: item.segment,
            channel: item.channel,
            facilityText: item.facility,
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictLanguageSnapshotViews(_ items: [StrictLanguageSnapshot]) -> [StrictLanguageSnapshotView] {
        var views: [StrictLanguageSnapshotView] = []
        for item in items {
            views.append(toStrictLanguageSnapshotView(item))
        }
        return views
    }

    static func sumStrictLanguageSnapshotView(_ view: StrictLanguageSnapshotView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCeiling
    }
}
