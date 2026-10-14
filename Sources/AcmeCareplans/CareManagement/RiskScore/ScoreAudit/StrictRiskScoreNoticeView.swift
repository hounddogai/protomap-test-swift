import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a strict risk score notice.
    final class StrictRiskScoreNoticeView {
        var codeText: String
        var name: String
        var archived: String
        var graceDays: String
        var currencyText: String
        var statusLabel: String

        init(codeText: String, name: String, archived: String, graceDays: String, currencyText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.archived = archived
            self.graceDays = graceDays
            self.currencyText = currencyText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictRiskScoreNoticeView(_ item: StrictRiskScoreNotice) -> StrictRiskScoreNoticeView {
        return StrictRiskScoreNoticeView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            archived: "\(item.archived)",
            graceDays: String(item.graceDays),
            currencyText: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictRiskScoreNoticeViews(_ items: [StrictRiskScoreNotice]) -> [StrictRiskScoreNoticeView] {
        var views: [StrictRiskScoreNoticeView] = []
        for item in items {
            views.append(toStrictRiskScoreNoticeView(item))
        }
        return views
    }

    static func sumStrictRiskScoreNoticeView(_ view: StrictRiskScoreNoticeView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
