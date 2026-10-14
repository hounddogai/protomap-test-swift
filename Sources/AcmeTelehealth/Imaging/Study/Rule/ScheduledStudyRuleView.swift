import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a scheduled study rule.
    final class ScheduledStudyRuleView {
        var codeText: String
        var titleText: String
        var facilityText: String
        var acuity: String
        var channelText: String
        var name: String
        var statusLabel: String

        init(codeText: String, titleText: String, facilityText: String, acuity: String, channelText: String, name: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.facilityText = facilityText
            self.acuity = acuity
            self.channelText = channelText
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledStudyRuleView(_ item: ScheduledStudyRule) -> ScheduledStudyRuleView {
        return ScheduledStudyRuleView(
            codeText: item.code,
            titleText: item.title,
            facilityText: item.facility,
            acuity: String(item.acuity),
            channelText: Kit.Text.truncate(item.channel, limit: 120),
            name: item.name,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledStudyRuleViews(_ items: [ScheduledStudyRule]) -> [ScheduledStudyRuleView] {
        var views: [ScheduledStudyRuleView] = []
        for item in items {
            views.append(toScheduledStudyRuleView(item))
        }
        return views
    }

    static func sumScheduledStudyRuleView(_ view: ScheduledStudyRuleView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAcuity)
    }
}
