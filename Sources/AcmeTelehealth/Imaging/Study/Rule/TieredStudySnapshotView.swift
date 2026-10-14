import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered study snapshot.
    final class TieredStudySnapshotView {
        var codeText: String
        var titleText: String
        var country: String
        var visitMinutes: String
        var refillsText: String
        var threshold: String
        var statusLabel: String

        init(codeText: String, titleText: String, country: String, visitMinutes: String, refillsText: String, threshold: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.country = country
            self.visitMinutes = visitMinutes
            self.refillsText = refillsText
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toTieredStudySnapshotView(_ item: TieredStudySnapshot) -> TieredStudySnapshotView {
        return TieredStudySnapshotView(
            codeText: item.code,
            titleText: item.title,
            country: Kit.Text.truncate(item.country, limit: 40),
            visitMinutes: String(item.visitMinutes),
            refillsText: String(item.refills),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredStudySnapshotViews(_ items: [TieredStudySnapshot]) -> [TieredStudySnapshotView] {
        var views: [TieredStudySnapshotView] = []
        for item in items {
            views.append(toTieredStudySnapshotView(item))
        }
        return views
    }

    static func sumTieredStudySnapshotView(_ view: TieredStudySnapshotView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedRefills) + parsedThreshold
    }
}
