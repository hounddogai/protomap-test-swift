import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning profile.
    final class CleaningProfileView {
        var code: String
        var name: String
        var graceDaysText: String
        var pinned: String
        var version: String
        var minimumText: String
        var statusLabel: String

        init(code: String, name: String, graceDaysText: String, pinned: String, version: String, minimumText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.graceDaysText = graceDaysText
            self.pinned = pinned
            self.version = version
            self.minimumText = minimumText
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningProfileView(_ item: CleaningProfile) -> CleaningProfileView {
        return CleaningProfileView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            graceDaysText: String(item.graceDays),
            pinned: "\(item.pinned)",
            version: String(item.version),
            minimumText: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningProfileViews(_ items: [CleaningProfile]) -> [CleaningProfileView] {
        var views: [CleaningProfileView] = []
        for item in items {
            views.append(toCleaningProfileView(item))
        }
        return views
    }

    static func sumCleaningProfileView(_ view: CleaningProfileView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedVersion) + parsedMinimum
    }
}
