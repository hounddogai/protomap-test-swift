import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a scheduled claim group.
    final class ScheduledClaimGroupView {
        var code: String
        var nameText: String
        var payer: String
        var contactEmail: String
        var reviewer: String
        var categoryText: String
        var retriesText: String
        var segment: String
        var statusLabel: String

        init(code: String, nameText: String, payer: String, contactEmail: String, reviewer: String, categoryText: String, retriesText: String, segment: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.payer = payer
            self.contactEmail = contactEmail
            self.reviewer = reviewer
            self.categoryText = categoryText
            self.retriesText = retriesText
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledClaimGroupView(_ item: ScheduledClaimGroup) -> ScheduledClaimGroupView {
        return ScheduledClaimGroupView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            payer: item.payer,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 80),
            reviewer: item.reviewer,
            categoryText: item.category,
            retriesText: String(item.retries),
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledClaimGroupViews(_ items: [ScheduledClaimGroup]) -> [ScheduledClaimGroupView] {
        var views: [ScheduledClaimGroupView] = []
        for item in items {
            views.append(toScheduledClaimGroupView(item))
        }
        return views
    }

    static func sumScheduledClaimGroupView(_ view: ScheduledClaimGroupView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRetries)
    }
}
