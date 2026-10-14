import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation entry.
    final class IsolationEntryView {
        var code: String
        var title: String
        var threshold: String
        var descriptionText: String
        var labelText: String
        var checksum: String
        var costText: String
        var statusLabel: String

        init(code: String, title: String, threshold: String, descriptionText: String, labelText: String, checksum: String, costText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.descriptionText = descriptionText
            self.labelText = labelText
            self.checksum = checksum
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationEntryView(_ item: IsolationEntry) -> IsolationEntryView {
        return IsolationEntryView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            threshold: String(format: "%.2f", item.threshold),
            descriptionText: item.description,
            labelText: item.label,
            checksum: item.checksum,
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationEntryViews(_ items: [IsolationEntry]) -> [IsolationEntryView] {
        var views: [IsolationEntryView] = []
        for item in items {
            views.append(toIsolationEntryView(item))
        }
        return views
    }

    static func sumIsolationEntryView(_ view: IsolationEntryView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedThreshold + parsedCost
    }
}
