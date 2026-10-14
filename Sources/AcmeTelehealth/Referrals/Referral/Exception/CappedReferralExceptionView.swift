import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped referral exception.
    final class CappedReferralExceptionView {
        var codeText: String
        var nameText: String
        var reviewerText: String
        var budget: String
        var visitMinutes: String
        var retriesText: String
        var dosageMgText: String
        var ceiling: String
        var acuity: String
        var maximumText: String
        var statusLabel: String

        init(codeText: String, nameText: String, reviewerText: String, budget: String, visitMinutes: String, retriesText: String, dosageMgText: String, ceiling: String, acuity: String, maximumText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.reviewerText = reviewerText
            self.budget = budget
            self.visitMinutes = visitMinutes
            self.retriesText = retriesText
            self.dosageMgText = dosageMgText
            self.ceiling = ceiling
            self.acuity = acuity
            self.maximumText = maximumText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedReferralExceptionView(_ item: CappedReferralException) -> CappedReferralExceptionView {
        return CappedReferralExceptionView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            nameText: Kit.Text.truncate(item.name, limit: 80),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 40),
            budget: String(format: "%.2f", item.budget),
            visitMinutes: String(item.visitMinutes),
            retriesText: String(item.retries),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            ceiling: String(format: "%.2f", item.ceiling),
            acuity: String(item.acuity),
            maximumText: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedReferralExceptionViews(_ items: [CappedReferralException]) -> [CappedReferralExceptionView] {
        var views: [CappedReferralExceptionView] = []
        for item in items {
            views.append(toCappedReferralExceptionView(item))
        }
        return views
    }

    static func sumCappedReferralExceptionView(_ view: CappedReferralExceptionView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedBudget + Double(parsedVisitMinutes) + Double(parsedRetries)
    }
}
