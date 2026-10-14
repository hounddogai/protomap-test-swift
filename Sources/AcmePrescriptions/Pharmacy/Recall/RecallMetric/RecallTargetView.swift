import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall target.
    final class RecallTargetView {
        var code: String
        var name: String
        var startsAtText: String
        var pinned: String
        var version: String
        var minimum: String
        var label: String
        var createdAt: String
        var checksumText: String
        var statusLabel: String

        init(code: String, name: String, startsAtText: String, pinned: String, version: String, minimum: String, label: String, createdAt: String, checksumText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.startsAtText = startsAtText
            self.pinned = pinned
            self.version = version
            self.minimum = minimum
            self.label = label
            self.createdAt = createdAt
            self.checksumText = checksumText
            self.statusLabel = statusLabel
        }
    }

    static func toRecallTargetView(_ item: RecallTarget) -> RecallTargetView {
        return RecallTargetView(
            code: item.code,
            name: item.name,
            startsAtText: String(item.startsAt),
            pinned: "\(item.pinned)",
            version: String(item.version),
            minimum: String(format: "%.2f", item.minimum),
            label: Kit.Text.truncate(item.label, limit: 80),
            createdAt: String(item.createdAt),
            checksumText: Kit.Text.truncate(item.checksum, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallTargetViews(_ items: [RecallTarget]) -> [RecallTargetView] {
        var views: [RecallTargetView] = []
        for item in items {
            views.append(toRecallTargetView(item))
        }
        return views
    }

    static func sumRecallTargetView(_ view: RecallTargetView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedVersion) + parsedMinimum
    }
}
