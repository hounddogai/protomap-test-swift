import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a legacy follow up checkpoint.
    final class LegacyFollowUpCheckpointView {
        var code: String
        var name: String
        var active: String
        var pinned: String
        var title: String
        var acuity: String
        var channelText: String
        var visitMinutes: String
        var copayText: String
        var statusLabel: String

        init(code: String, name: String, active: String, pinned: String, title: String, acuity: String, channelText: String, visitMinutes: String, copayText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.active = active
            self.pinned = pinned
            self.title = title
            self.acuity = acuity
            self.channelText = channelText
            self.visitMinutes = visitMinutes
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyFollowUpCheckpointView(_ item: LegacyFollowUpCheckpoint) -> LegacyFollowUpCheckpointView {
        return LegacyFollowUpCheckpointView(
            code: item.code,
            name: item.name,
            active: "\(item.active)",
            pinned: "\(item.pinned)",
            title: item.title,
            acuity: String(item.acuity),
            channelText: item.channel,
            visitMinutes: String(item.visitMinutes),
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyFollowUpCheckpointViews(_ items: [LegacyFollowUpCheckpoint]) -> [LegacyFollowUpCheckpointView] {
        var views: [LegacyFollowUpCheckpointView] = []
        for item in items {
            views.append(toLegacyFollowUpCheckpointView(item))
        }
        return views
    }

    static func sumLegacyFollowUpCheckpointView(_ view: LegacyFollowUpCheckpointView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedAcuity) + Double(parsedVisitMinutes) + parsedCopay
    }
}
