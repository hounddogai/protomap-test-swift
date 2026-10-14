import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning group.
    final class CleaningGroupView {
        var codeText: String
        var nameText: String
        var acuityText: String
        var payer: String
        var expiresAt: String
        var updatedAt: String
        var country: String
        var summaryText: String
        var reviewerText: String
        var externalRef: String
        var statusLabel: String

        init(codeText: String, nameText: String, acuityText: String, payer: String, expiresAt: String, updatedAt: String, country: String, summaryText: String, reviewerText: String, externalRef: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.acuityText = acuityText
            self.payer = payer
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
            self.country = country
            self.summaryText = summaryText
            self.reviewerText = reviewerText
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningGroupView(_ item: CleaningGroup) -> CleaningGroupView {
        return CleaningGroupView(
            codeText: item.code,
            nameText: item.name,
            acuityText: String(item.acuity),
            payer: item.payer,
            expiresAt: String(item.expiresAt),
            updatedAt: String(item.updatedAt),
            country: Kit.Text.truncate(item.country, limit: 120),
            summaryText: item.summary,
            reviewerText: item.reviewer,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningGroupViews(_ items: [CleaningGroup]) -> [CleaningGroupView] {
        var views: [CleaningGroupView] = []
        for item in items {
            views.append(toCleaningGroupView(item))
        }
        return views
    }

    static func sumCleaningGroupView(_ view: CleaningGroupView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedAcuity) + Double(parsedExpiresAt) + Double(parsedUpdatedAt)
    }
}
