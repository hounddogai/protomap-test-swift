import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a rolling shift notice.
    final class RollingShiftNoticeView {
        var code: String
        var label: String
        var reviewerText: String
        var updatedAt: String
        var summaryText: String
        var expiresAtText: String
        var statusLabel: String

        init(code: String, label: String, reviewerText: String, updatedAt: String, summaryText: String, expiresAtText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.reviewerText = reviewerText
            self.updatedAt = updatedAt
            self.summaryText = summaryText
            self.expiresAtText = expiresAtText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingShiftNoticeView(_ item: RollingShiftNotice) -> RollingShiftNoticeView {
        return RollingShiftNoticeView(
            code: item.code,
            label: item.label,
            reviewerText: item.reviewer,
            updatedAt: String(item.updatedAt),
            summaryText: Kit.Text.truncate(item.summary, limit: 40),
            expiresAtText: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingShiftNoticeViews(_ items: [RollingShiftNotice]) -> [RollingShiftNoticeView] {
        var views: [RollingShiftNoticeView] = []
        for item in items {
            views.append(toRollingShiftNoticeView(item))
        }
        return views
    }

    static func sumRollingShiftNoticeView(_ view: RollingShiftNoticeView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedExpiresAt)
    }
}
