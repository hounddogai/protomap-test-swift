import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled isolation digest.
    final class ScheduledIsolationDigestView {
        var code: String
        var title: String
        var clinicianID: String
        var floorValue: String
        var activeText: String
        var graceDays: String
        var statusLabel: String

        init(code: String, title: String, clinicianID: String, floorValue: String, activeText: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.floorValue = floorValue
            self.activeText = activeText
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledIsolationDigestView(_ item: ScheduledIsolationDigest) -> ScheduledIsolationDigestView {
        return ScheduledIsolationDigestView(
            code: item.code,
            title: item.title,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            floorValue: String(format: "%.2f", item.floorValue),
            activeText: "\(item.active)",
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledIsolationDigestViews(_ items: [ScheduledIsolationDigest]) -> [ScheduledIsolationDigestView] {
        var views: [ScheduledIsolationDigestView] = []
        for item in items {
            views.append(toScheduledIsolationDigestView(item))
        }
        return views
    }

    static func sumScheduledIsolationDigestView(_ view: ScheduledIsolationDigestView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedFloorValue + Double(parsedGraceDays)
    }
}
