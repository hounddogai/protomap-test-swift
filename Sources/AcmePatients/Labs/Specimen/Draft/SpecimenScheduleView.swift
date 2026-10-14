import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen schedule.
    final class SpecimenScheduleView {
        var code: String
        var titleText: String
        var visitMinutes: String
        var copay: String
        var payerText: String
        var budget: String
        var statusLabel: String

        init(code: String, titleText: String, visitMinutes: String, copay: String, payerText: String, budget: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.visitMinutes = visitMinutes
            self.copay = copay
            self.payerText = payerText
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenScheduleView(_ item: SpecimenSchedule) -> SpecimenScheduleView {
        return SpecimenScheduleView(
            code: item.code,
            titleText: item.title,
            visitMinutes: String(item.visitMinutes),
            copay: String(format: "%.2f", item.copay),
            payerText: item.payer,
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenScheduleViews(_ items: [SpecimenSchedule]) -> [SpecimenScheduleView] {
        var views: [SpecimenScheduleView] = []
        for item in items {
            views.append(toSpecimenScheduleView(item))
        }
        return views
    }

    static func sumSpecimenScheduleView(_ view: SpecimenScheduleView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedVisitMinutes) + parsedCopay + parsedBudget
    }
}
