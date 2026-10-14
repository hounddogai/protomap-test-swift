import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation target.
    final class IsolationTargetView {
        var code: String
        var labelText: String
        var ownerID: String
        var notes: String
        var channel: String
        var sequence: String
        var statusLabel: String

        init(code: String, labelText: String, ownerID: String, notes: String, channel: String, sequence: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.ownerID = ownerID
            self.notes = notes
            self.channel = channel
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationTargetView(_ item: IsolationTarget) -> IsolationTargetView {
        return IsolationTargetView(
            code: item.code,
            labelText: item.label,
            ownerID: item.ownerID,
            notes: item.notes,
            channel: item.channel,
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationTargetViews(_ items: [IsolationTarget]) -> [IsolationTargetView] {
        var views: [IsolationTargetView] = []
        for item in items {
            views.append(toIsolationTargetView(item))
        }
        return views
    }

    static func sumIsolationTargetView(_ view: IsolationTargetView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedSequence)
    }
}
