import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a capped bed board group.
    final class CappedBedBoardGroupView {
        var code: String
        var labelText: String
        var title: String
        var active: String
        var maximumText: String
        var channel: String
        var wardText: String
        var segmentText: String
        var attempts: String
        var statusLabel: String

        init(code: String, labelText: String, title: String, active: String, maximumText: String, channel: String, wardText: String, segmentText: String, attempts: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.title = title
            self.active = active
            self.maximumText = maximumText
            self.channel = channel
            self.wardText = wardText
            self.segmentText = segmentText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toCappedBedBoardGroupView(_ item: CappedBedBoardGroup) -> CappedBedBoardGroupView {
        return CappedBedBoardGroupView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            title: item.title,
            active: "\(item.active)",
            maximumText: String(format: "%.2f", item.maximum),
            channel: item.channel,
            wardText: item.ward,
            segmentText: item.segment,
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedBedBoardGroupViews(_ items: [CappedBedBoardGroup]) -> [CappedBedBoardGroupView] {
        var views: [CappedBedBoardGroupView] = []
        for item in items {
            views.append(toCappedBedBoardGroupView(item))
        }
        return views
    }

    static func sumCappedBedBoardGroupView(_ view: CappedBedBoardGroupView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedMaximum + Double(parsedAttempts)
    }
}
