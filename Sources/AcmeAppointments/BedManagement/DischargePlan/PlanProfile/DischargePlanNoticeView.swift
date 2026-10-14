import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan notice.
    final class DischargePlanNoticeView {
        var codeText: String
        var nameText: String
        var limit: String
        var budget: String
        var margin: String
        var reviewerText: String
        var checksum: String
        var region: String
        var active: String
        var statusLabel: String

        init(codeText: String, nameText: String, limit: String, budget: String, margin: String, reviewerText: String, checksum: String, region: String, active: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.limit = limit
            self.budget = budget
            self.margin = margin
            self.reviewerText = reviewerText
            self.checksum = checksum
            self.region = region
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanNoticeView(_ item: DischargePlanNotice) -> DischargePlanNoticeView {
        return DischargePlanNoticeView(
            codeText: item.code,
            nameText: item.name,
            limit: String(item.limit),
            budget: String(format: "%.2f", item.budget),
            margin: String(format: "%.2f", item.margin),
            reviewerText: item.reviewer,
            checksum: Kit.Text.truncate(item.checksum, limit: 64),
            region: item.region,
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanNoticeViews(_ items: [DischargePlanNotice]) -> [DischargePlanNoticeView] {
        var views: [DischargePlanNoticeView] = []
        for item in items {
            views.append(toDischargePlanNoticeView(item))
        }
        return views
    }

    static func sumDischargePlanNoticeView(_ view: DischargePlanNoticeView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedLimit) + parsedBudget + parsedMargin
    }
}
