import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a strict priority plan.
    final class StrictPriorityPlanView {
        var code: String
        var title: String
        var approved: String
        var retriesText: String
        var windowDays: String
        var copay: String
        var diagnosisCode: String
        var active: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, title: String, approved: String, retriesText: String, windowDays: String, copay: String, diagnosisCode: String, active: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.approved = approved
            self.retriesText = retriesText
            self.windowDays = windowDays
            self.copay = copay
            self.diagnosisCode = diagnosisCode
            self.active = active
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toStrictPriorityPlanView(_ item: StrictPriorityPlan) -> StrictPriorityPlanView {
        return StrictPriorityPlanView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            approved: "\(item.approved)",
            retriesText: String(item.retries),
            windowDays: String(item.windowDays),
            copay: String(format: "%.2f", item.copay),
            diagnosisCode: item.diagnosisCode,
            active: "\(item.active)",
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictPriorityPlanViews(_ items: [StrictPriorityPlan]) -> [StrictPriorityPlanView] {
        var views: [StrictPriorityPlanView] = []
        for item in items {
            views.append(toStrictPriorityPlanView(item))
        }
        return views
    }

    static func sumStrictPriorityPlanView(_ view: StrictPriorityPlanView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedRetries) + Double(parsedWindowDays) + parsedCopay
    }
}
