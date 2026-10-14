import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up exception.
    final class FollowUpExceptionView {
        var codeText: String
        var labelText: String
        var channel: String
        var limitText: String
        var copay: String
        var source: String
        var checksum: String
        var nameText: String
        var floorValue: String
        var statusLabel: String

        init(codeText: String, labelText: String, channel: String, limitText: String, copay: String, source: String, checksum: String, nameText: String, floorValue: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.channel = channel
            self.limitText = limitText
            self.copay = copay
            self.source = source
            self.checksum = checksum
            self.nameText = nameText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpExceptionView(_ item: FollowUpException) -> FollowUpExceptionView {
        return FollowUpExceptionView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            channel: item.channel,
            limitText: String(item.limit),
            copay: String(format: "%.2f", item.copay),
            source: Kit.Text.truncate(item.source, limit: 80),
            checksum: Kit.Text.truncate(item.checksum, limit: 120),
            nameText: Kit.Text.truncate(item.name, limit: 80),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpExceptionViews(_ items: [FollowUpException]) -> [FollowUpExceptionView] {
        var views: [FollowUpExceptionView] = []
        for item in items {
            views.append(toFollowUpExceptionView(item))
        }
        return views
    }

    static func sumFollowUpExceptionView(_ view: FollowUpExceptionView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedLimit) + parsedCopay + parsedFloorValue
    }
}
