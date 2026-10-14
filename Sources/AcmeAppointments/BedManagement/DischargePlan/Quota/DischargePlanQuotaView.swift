import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan quota.
    final class DischargePlanQuotaView {
        var code: String
        var label: String
        var sourceText: String
        var titleText: String
        var descriptionText: String
        var activeText: String
        var sequence: String
        var budget: String
        var endsAt: String
        var statusLabel: String

        init(code: String, label: String, sourceText: String, titleText: String, descriptionText: String, activeText: String, sequence: String, budget: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.sourceText = sourceText
            self.titleText = titleText
            self.descriptionText = descriptionText
            self.activeText = activeText
            self.sequence = sequence
            self.budget = budget
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanQuotaView(_ item: DischargePlanQuota) -> DischargePlanQuotaView {
        return DischargePlanQuotaView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            sourceText: item.source,
            titleText: item.title,
            descriptionText: Kit.Text.truncate(item.description, limit: 40),
            activeText: "\(item.active)",
            sequence: String(item.sequence),
            budget: String(format: "%.2f", item.budget),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanQuotaViews(_ items: [DischargePlanQuota]) -> [DischargePlanQuotaView] {
        var views: [DischargePlanQuotaView] = []
        for item in items {
            views.append(toDischargePlanQuotaView(item))
        }
        return views
    }

    static func sumDischargePlanQuotaView(_ view: DischargePlanQuotaView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedSequence) + parsedBudget + Double(parsedEndsAt)
    }
}
