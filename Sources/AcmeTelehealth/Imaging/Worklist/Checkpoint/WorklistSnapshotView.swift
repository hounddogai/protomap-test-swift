import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist snapshot.
    final class WorklistSnapshotView {
        var code: String
        var titleText: String
        var rate: String
        var cost: String
        var ratio: String
        var statusLabel: String

        init(code: String, titleText: String, rate: String, cost: String, ratio: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.rate = rate
            self.cost = cost
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistSnapshotView(_ item: WorklistSnapshot) -> WorklistSnapshotView {
        return WorklistSnapshotView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            rate: String(format: "%.2f", item.rate),
            cost: String(format: "%.2f", item.cost),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistSnapshotViews(_ items: [WorklistSnapshot]) -> [WorklistSnapshotView] {
        var views: [WorklistSnapshotView] = []
        for item in items {
            views.append(toWorklistSnapshotView(item))
        }
        return views
    }

    static func sumWorklistSnapshotView(_ view: WorklistSnapshotView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRate + parsedCost + parsedRatio
    }
}
