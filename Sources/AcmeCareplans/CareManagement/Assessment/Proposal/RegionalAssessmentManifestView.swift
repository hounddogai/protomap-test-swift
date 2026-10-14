import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a regional assessment manifest.
    final class RegionalAssessmentManifestView {
        var codeText: String
        var label: String
        var externalRef: String
        var amountText: String
        var pinned: String
        var approvedText: String
        var ownerID: String
        var archived: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, label: String, externalRef: String, amountText: String, pinned: String, approvedText: String, ownerID: String, archived: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.externalRef = externalRef
            self.amountText = amountText
            self.pinned = pinned
            self.approvedText = approvedText
            self.ownerID = ownerID
            self.archived = archived
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalAssessmentManifestView(_ item: RegionalAssessmentManifest) -> RegionalAssessmentManifestView {
        return RegionalAssessmentManifestView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 120),
            amountText: String(format: "%.2f", item.amount),
            pinned: "\(item.pinned)",
            approvedText: "\(item.approved)",
            ownerID: item.ownerID,
            archived: "\(item.archived)",
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalAssessmentManifestViews(_ items: [RegionalAssessmentManifest]) -> [RegionalAssessmentManifestView] {
        var views: [RegionalAssessmentManifestView] = []
        for item in items {
            views.append(toRegionalAssessmentManifestView(item))
        }
        return views
    }

    static func sumRegionalAssessmentManifestView(_ view: RegionalAssessmentManifestView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedAmount + Double(parsedExpiresAt)
    }
}
