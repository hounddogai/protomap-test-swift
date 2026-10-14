import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning snapshot.
    final class CleaningSnapshotView {
        var code: String
        var name: String
        var title: String
        var payerText: String
        var ratio: String
        var segmentText: String
        var statusLabel: String

        init(code: String, name: String, title: String, payerText: String, ratio: String, segmentText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.title = title
            self.payerText = payerText
            self.ratio = ratio
            self.segmentText = segmentText
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningSnapshotView(_ item: CleaningSnapshot) -> CleaningSnapshotView {
        return CleaningSnapshotView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 40),
            title: item.title,
            payerText: item.payer,
            ratio: String(format: "%.2f", item.ratio),
            segmentText: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningSnapshotViews(_ items: [CleaningSnapshot]) -> [CleaningSnapshotView] {
        var views: [CleaningSnapshotView] = []
        for item in items {
            views.append(toCleaningSnapshotView(item))
        }
        return views
    }

    static func sumCleaningSnapshotView(_ view: CleaningSnapshotView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
