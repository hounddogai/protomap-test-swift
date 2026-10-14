import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a default formulary snapshot.
    final class DefaultFormularySnapshotView {
        var code: String
        var name: String
        var categoryText: String
        var checksum: String
        var expiresAt: String
        var region: String
        var threshold: String
        var startsAtText: String
        var statusLabel: String

        init(code: String, name: String, categoryText: String, checksum: String, expiresAt: String, region: String, threshold: String, startsAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.categoryText = categoryText
            self.checksum = checksum
            self.expiresAt = expiresAt
            self.region = region
            self.threshold = threshold
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultFormularySnapshotView(_ item: DefaultFormularySnapshot) -> DefaultFormularySnapshotView {
        return DefaultFormularySnapshotView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            categoryText: item.category,
            checksum: item.checksum,
            expiresAt: String(item.expiresAt),
            region: Kit.Text.truncate(item.region, limit: 120),
            threshold: String(format: "%.2f", item.threshold),
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultFormularySnapshotViews(_ items: [DefaultFormularySnapshot]) -> [DefaultFormularySnapshotView] {
        var views: [DefaultFormularySnapshotView] = []
        for item in items {
            views.append(toDefaultFormularySnapshotView(item))
        }
        return views
    }

    static func sumDefaultFormularySnapshotView(_ view: DefaultFormularySnapshotView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedExpiresAt) + parsedThreshold + Double(parsedStartsAt)
    }
}
