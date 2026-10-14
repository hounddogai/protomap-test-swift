import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a pending task schedule.
    final class PendingTaskScheduleView {
        var code: String
        var title: String
        var revision: String
        var approvedText: String
        var endsAtText: String
        var allergy: String
        var currency: String
        var categoryText: String
        var wardText: String
        var amountText: String
        var statusLabel: String

        init(code: String, title: String, revision: String, approvedText: String, endsAtText: String, allergy: String, currency: String, categoryText: String, wardText: String, amountText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revision = revision
            self.approvedText = approvedText
            self.endsAtText = endsAtText
            self.allergy = allergy
            self.currency = currency
            self.categoryText = categoryText
            self.wardText = wardText
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingTaskScheduleView(_ item: PendingTaskSchedule) -> PendingTaskScheduleView {
        return PendingTaskScheduleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            revision: String(item.revision),
            approvedText: "\(item.approved)",
            endsAtText: String(item.endsAt),
            allergy: Kit.Text.truncate(item.allergy, limit: 80),
            currency: item.currency,
            categoryText: Kit.Text.truncate(item.category, limit: 120),
            wardText: item.ward,
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingTaskScheduleViews(_ items: [PendingTaskSchedule]) -> [PendingTaskScheduleView] {
        var views: [PendingTaskScheduleView] = []
        for item in items {
            views.append(toPendingTaskScheduleView(item))
        }
        return views
    }

    static func sumPendingTaskScheduleView(_ view: PendingTaskScheduleView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedRevision) + Double(parsedEndsAt) + parsedAmount
    }
}
