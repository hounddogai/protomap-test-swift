import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a lenient read snapshot.
    final class LenientReadSnapshotView {
        var code: String
        var titleText: String
        var pinnedText: String
        var locale: String
        var startsAt: String
        var minimumText: String
        var version: String
        var durationMinutesText: String
        var externalRef: String
        var floorValue: String
        var ceilingText: String
        var statusLabel: String

        init(code: String, titleText: String, pinnedText: String, locale: String, startsAt: String, minimumText: String, version: String, durationMinutesText: String, externalRef: String, floorValue: String, ceilingText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.pinnedText = pinnedText
            self.locale = locale
            self.startsAt = startsAt
            self.minimumText = minimumText
            self.version = version
            self.durationMinutesText = durationMinutesText
            self.externalRef = externalRef
            self.floorValue = floorValue
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientReadSnapshotView(_ item: LenientReadSnapshot) -> LenientReadSnapshotView {
        return LenientReadSnapshotView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            pinnedText: "\(item.pinned)",
            locale: Kit.Text.truncate(item.locale, limit: 64),
            startsAt: String(item.startsAt),
            minimumText: String(format: "%.2f", item.minimum),
            version: String(item.version),
            durationMinutesText: String(item.durationMinutes),
            externalRef: item.externalRef,
            floorValue: String(format: "%.2f", item.floorValue),
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientReadSnapshotViews(_ items: [LenientReadSnapshot]) -> [LenientReadSnapshotView] {
        var views: [LenientReadSnapshotView] = []
        for item in items {
            views.append(toLenientReadSnapshotView(item))
        }
        return views
    }

    static func sumLenientReadSnapshotView(_ view: LenientReadSnapshotView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedStartsAt) + parsedMinimum + Double(parsedVersion)
    }
}
