import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending follow up notice.
    final class PendingFollowUpNoticeView {
        var code: String
        var titleText: String
        var dosageMg: String
        var activeText: String
        var descriptionText: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, titleText: String, dosageMg: String, activeText: String, descriptionText: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.dosageMg = dosageMg
            self.activeText = activeText
            self.descriptionText = descriptionText
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toPendingFollowUpNoticeView(_ item: PendingFollowUpNotice) -> PendingFollowUpNoticeView {
        return PendingFollowUpNoticeView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            dosageMg: String(format: "%.2f", item.dosageMg),
            activeText: "\(item.active)",
            descriptionText: Kit.Text.truncate(item.description, limit: 64),
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingFollowUpNoticeViews(_ items: [PendingFollowUpNotice]) -> [PendingFollowUpNoticeView] {
        var views: [PendingFollowUpNoticeView] = []
        for item in items {
            views.append(toPendingFollowUpNoticeView(item))
        }
        return views
    }

    static func sumPendingFollowUpNoticeView(_ view: PendingFollowUpNoticeView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
