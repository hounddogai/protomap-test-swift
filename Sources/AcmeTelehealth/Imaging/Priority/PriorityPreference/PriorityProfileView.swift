import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority profile.
    final class PriorityProfileView {
        var codeText: String
        var title: String
        var sequence: String
        var unitText: String
        var budget: String
        var locale: String
        var ownerIDText: String
        var archived: String
        var country: String
        var approvedText: String
        var statusLabel: String

        init(codeText: String, title: String, sequence: String, unitText: String, budget: String, locale: String, ownerIDText: String, archived: String, country: String, approvedText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.sequence = sequence
            self.unitText = unitText
            self.budget = budget
            self.locale = locale
            self.ownerIDText = ownerIDText
            self.archived = archived
            self.country = country
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityProfileView(_ item: PriorityProfile) -> PriorityProfileView {
        return PriorityProfileView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            sequence: String(item.sequence),
            unitText: item.unit,
            budget: String(format: "%.2f", item.budget),
            locale: item.locale,
            ownerIDText: item.ownerID,
            archived: "\(item.archived)",
            country: Kit.Text.truncate(item.country, limit: 80),
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityProfileViews(_ items: [PriorityProfile]) -> [PriorityProfileView] {
        var views: [PriorityProfileView] = []
        for item in items {
            views.append(toPriorityProfileView(item))
        }
        return views
    }

    static func sumPriorityProfileView(_ view: PriorityProfileView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedSequence) + parsedBudget
    }
}
