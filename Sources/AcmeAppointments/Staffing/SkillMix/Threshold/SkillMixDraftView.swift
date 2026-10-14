import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix draft.
    final class SkillMixDraftView {
        var code: String
        var name: String
        var quantityText: String
        var archived: String
        var cost: String
        var segment: String
        var windowDays: String
        var reviewer: String
        var graceDays: String
        var approved: String
        var acuity: String
        var statusLabel: String

        init(code: String, name: String, quantityText: String, archived: String, cost: String, segment: String, windowDays: String, reviewer: String, graceDays: String, approved: String, acuity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.quantityText = quantityText
            self.archived = archived
            self.cost = cost
            self.segment = segment
            self.windowDays = windowDays
            self.reviewer = reviewer
            self.graceDays = graceDays
            self.approved = approved
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixDraftView(_ item: SkillMixDraft) -> SkillMixDraftView {
        return SkillMixDraftView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 64),
            quantityText: String(item.quantity),
            archived: "\(item.archived)",
            cost: String(format: "%.2f", item.cost),
            segment: item.segment,
            windowDays: String(item.windowDays),
            reviewer: item.reviewer,
            graceDays: String(item.graceDays),
            approved: "\(item.approved)",
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixDraftViews(_ items: [SkillMixDraft]) -> [SkillMixDraftView] {
        var views: [SkillMixDraftView] = []
        for item in items {
            views.append(toSkillMixDraftView(item))
        }
        return views
    }

    static func sumSkillMixDraftView(_ view: SkillMixDraftView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedQuantity) + parsedCost + Double(parsedWindowDays)
    }
}
