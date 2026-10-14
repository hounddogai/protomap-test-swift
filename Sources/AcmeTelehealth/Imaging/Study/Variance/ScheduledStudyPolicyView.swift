import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a scheduled study policy.
    final class ScheduledStudyPolicyView {
        var code: String
        var label: String
        var ownerID: String
        var diagnosisCodeText: String
        var revision: String
        var discountText: String
        var cost: String
        var graceDays: String
        var statusLabel: String

        init(code: String, label: String, ownerID: String, diagnosisCodeText: String, revision: String, discountText: String, cost: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.diagnosisCodeText = diagnosisCodeText
            self.revision = revision
            self.discountText = discountText
            self.cost = cost
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledStudyPolicyView(_ item: ScheduledStudyPolicy) -> ScheduledStudyPolicyView {
        return ScheduledStudyPolicyView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            ownerID: item.ownerID,
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            revision: String(item.revision),
            discountText: String(format: "%.2f", item.discount),
            cost: String(format: "%.2f", item.cost),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledStudyPolicyViews(_ items: [ScheduledStudyPolicy]) -> [ScheduledStudyPolicyView] {
        var views: [ScheduledStudyPolicyView] = []
        for item in items {
            views.append(toScheduledStudyPolicyView(item))
        }
        return views
    }

    static func sumScheduledStudyPolicyView(_ view: ScheduledStudyPolicyView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedRevision) + parsedDiscount + parsedCost
    }
}
