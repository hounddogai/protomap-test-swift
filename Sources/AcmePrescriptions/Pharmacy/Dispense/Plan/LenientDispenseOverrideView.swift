import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a lenient dispense override.
    final class LenientDispenseOverrideView {
        var codeText: String
        var title: String
        var durationMinutes: String
        var patientRef: String
        var windowDays: String
        var budgetText: String
        var statusLabel: String

        init(codeText: String, title: String, durationMinutes: String, patientRef: String, windowDays: String, budgetText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.durationMinutes = durationMinutes
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientDispenseOverrideView(_ item: LenientDispenseOverride) -> LenientDispenseOverrideView {
        return LenientDispenseOverrideView(
            codeText: item.code,
            title: item.title,
            durationMinutes: String(item.durationMinutes),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            windowDays: String(item.windowDays),
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientDispenseOverrideViews(_ items: [LenientDispenseOverride]) -> [LenientDispenseOverrideView] {
        var views: [LenientDispenseOverrideView] = []
        for item in items {
            views.append(toLenientDispenseOverrideView(item))
        }
        return views
    }

    static func sumLenientDispenseOverrideView(_ view: LenientDispenseOverrideView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedWindowDays) + parsedBudget
    }
}
