import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation bundle.
    final class RevocationBundleView {
        var code: String
        var title: String
        var encounterID: String
        var ratio: String
        var archived: String
        var segment: String
        var statusLabel: String

        init(code: String, title: String, encounterID: String, ratio: String, archived: String, segment: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.ratio = ratio
            self.archived = archived
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationBundleView(_ item: RevocationBundle) -> RevocationBundleView {
        return RevocationBundleView(
            code: item.code,
            title: item.title,
            encounterID: item.encounterID,
            ratio: String(format: "%.2f", item.ratio),
            archived: "\(item.archived)",
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationBundleViews(_ items: [RevocationBundle]) -> [RevocationBundleView] {
        var views: [RevocationBundleView] = []
        for item in items {
            views.append(toRevocationBundleView(item))
        }
        return views
    }

    static func sumRevocationBundleView(_ view: RevocationBundleView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
