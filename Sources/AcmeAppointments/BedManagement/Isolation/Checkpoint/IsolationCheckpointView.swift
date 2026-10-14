import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation checkpoint.
    final class IsolationCheckpointView {
        var codeText: String
        var label: String
        var ratio: String
        var archived: String
        var weight: String
        var statusLabel: String

        init(codeText: String, label: String, ratio: String, archived: String, weight: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ratio = ratio
            self.archived = archived
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationCheckpointView(_ item: IsolationCheckpoint) -> IsolationCheckpointView {
        return IsolationCheckpointView(
            codeText: item.code,
            label: item.label,
            ratio: String(format: "%.2f", item.ratio),
            archived: "\(item.archived)",
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationCheckpointViews(_ items: [IsolationCheckpoint]) -> [IsolationCheckpointView] {
        var views: [IsolationCheckpointView] = []
        for item in items {
            views.append(toIsolationCheckpointView(item))
        }
        return views
    }

    static func sumIsolationCheckpointView(_ view: IsolationCheckpointView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedRatio + parsedWeight
    }
}
