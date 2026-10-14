import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board rule.
    final class BedBoardRuleView {
        var code: String
        var name: String
        var reviewerText: String
        var retries: String
        var endsAt: String
        var checksum: String
        var limit: String
        var statusLabel: String

        init(code: String, name: String, reviewerText: String, retries: String, endsAt: String, checksum: String, limit: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.reviewerText = reviewerText
            self.retries = retries
            self.endsAt = endsAt
            self.checksum = checksum
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardRuleView(_ item: BedBoardRule) -> BedBoardRuleView {
        return BedBoardRuleView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 80),
            reviewerText: item.reviewer,
            retries: String(item.retries),
            endsAt: String(item.endsAt),
            checksum: item.checksum,
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardRuleViews(_ items: [BedBoardRule]) -> [BedBoardRuleView] {
        var views: [BedBoardRuleView] = []
        for item in items {
            views.append(toBedBoardRuleView(item))
        }
        return views
    }

    static func sumBedBoardRuleView(_ view: BedBoardRuleView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedRetries) + Double(parsedEndsAt) + Double(parsedLimit)
    }
}
