import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim allocation.
    final class ClaimAllocationView {
        var code: String
        var nameText: String
        var approved: String
        var reviewerText: String
        var acuity: String
        var ratioText: String
        var margin: String
        var statusLabel: String

        init(code: String, nameText: String, approved: String, reviewerText: String, acuity: String, ratioText: String, margin: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.approved = approved
            self.reviewerText = reviewerText
            self.acuity = acuity
            self.ratioText = ratioText
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toClaimAllocationView(_ item: ClaimAllocation) -> ClaimAllocationView {
        return ClaimAllocationView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            approved: "\(item.approved)",
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 80),
            acuity: String(item.acuity),
            ratioText: String(format: "%.2f", item.ratio),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimAllocationViews(_ items: [ClaimAllocation]) -> [ClaimAllocationView] {
        var views: [ClaimAllocationView] = []
        for item in items {
            views.append(toClaimAllocationView(item))
        }
        return views
    }

    static func sumClaimAllocationView(_ view: ClaimAllocationView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedAcuity) + parsedRatio + parsedMargin
    }
}
