import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped referral allocation.
    final class CappedReferralAllocationView {
        var code: String
        var name: String
        var limitText: String
        var encounterID: String
        var attemptsText: String
        var visitMinutes: String
        var budget: String
        var statusLabel: String

        init(code: String, name: String, limitText: String, encounterID: String, attemptsText: String, visitMinutes: String, budget: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limitText = limitText
            self.encounterID = encounterID
            self.attemptsText = attemptsText
            self.visitMinutes = visitMinutes
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toCappedReferralAllocationView(_ item: CappedReferralAllocation) -> CappedReferralAllocationView {
        return CappedReferralAllocationView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            limitText: String(item.limit),
            encounterID: item.encounterID,
            attemptsText: String(item.attempts),
            visitMinutes: String(item.visitMinutes),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedReferralAllocationViews(_ items: [CappedReferralAllocation]) -> [CappedReferralAllocationView] {
        var views: [CappedReferralAllocationView] = []
        for item in items {
            views.append(toCappedReferralAllocationView(item))
        }
        return views
    }

    static func sumCappedReferralAllocationView(_ view: CappedReferralAllocationView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedLimit) + Double(parsedAttempts) + Double(parsedVisitMinutes)
    }
}
