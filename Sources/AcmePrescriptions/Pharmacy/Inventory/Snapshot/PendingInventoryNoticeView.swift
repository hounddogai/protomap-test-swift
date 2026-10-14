import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending inventory notice.
    final class PendingInventoryNoticeView {
        var codeText: String
        var titleText: String
        var currency: String
        var visitMinutes: String
        var reviewer: String
        var diagnosisCodeText: String
        var locale: String
        var statusLabel: String

        init(codeText: String, titleText: String, currency: String, visitMinutes: String, reviewer: String, diagnosisCodeText: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.currency = currency
            self.visitMinutes = visitMinutes
            self.reviewer = reviewer
            self.diagnosisCodeText = diagnosisCodeText
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toPendingInventoryNoticeView(_ item: PendingInventoryNotice) -> PendingInventoryNoticeView {
        return PendingInventoryNoticeView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            titleText: Kit.Text.truncate(item.title, limit: 120),
            currency: item.currency,
            visitMinutes: String(item.visitMinutes),
            reviewer: item.reviewer,
            diagnosisCodeText: item.diagnosisCode,
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingInventoryNoticeViews(_ items: [PendingInventoryNotice]) -> [PendingInventoryNoticeView] {
        var views: [PendingInventoryNoticeView] = []
        for item in items {
            views.append(toPendingInventoryNoticeView(item))
        }
        return views
    }

    static func sumPendingInventoryNoticeView(_ view: PendingInventoryNoticeView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedVisitMinutes)
    }
}
