import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach profile.
    final class OutreachProfileView {
        var code: String
        var titleText: String
        var endsAt: String
        var budget: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, titleText: String, endsAt: String, budget: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.endsAt = endsAt
            self.budget = budget
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachProfileView(_ item: OutreachProfile) -> OutreachProfileView {
        return OutreachProfileView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: Kit.Text.truncate(item.title, limit: 80),
            endsAt: String(item.endsAt),
            budget: String(format: "%.2f", item.budget),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachProfileViews(_ items: [OutreachProfile]) -> [OutreachProfileView] {
        var views: [OutreachProfileView] = []
        for item in items {
            views.append(toOutreachProfileView(item))
        }
        return views
    }

    static func sumOutreachProfileView(_ view: OutreachProfileView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedEndsAt) + parsedBudget + parsedDosageMg
    }
}
