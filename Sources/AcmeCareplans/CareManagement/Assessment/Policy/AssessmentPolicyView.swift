import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment policy.
    final class AssessmentPolicyView {
        var code: String
        var title: String
        var windowDays: String
        var durationMinutes: String
        var payer: String
        var statusLabel: String

        init(code: String, title: String, windowDays: String, durationMinutes: String, payer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.durationMinutes = durationMinutes
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentPolicyView(_ item: AssessmentPolicy) -> AssessmentPolicyView {
        return AssessmentPolicyView(
            code: item.code,
            title: item.title,
            windowDays: String(item.windowDays),
            durationMinutes: String(item.durationMinutes),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentPolicyViews(_ items: [AssessmentPolicy]) -> [AssessmentPolicyView] {
        var views: [AssessmentPolicyView] = []
        for item in items {
            views.append(toAssessmentPolicyView(item))
        }
        return views
    }

    static func sumAssessmentPolicyView(_ view: AssessmentPolicyView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedDurationMinutes)
    }
}
