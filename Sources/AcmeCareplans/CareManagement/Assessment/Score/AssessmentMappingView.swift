import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment mapping.
    final class AssessmentMappingView {
        var code: String
        var name: String
        var payerText: String
        var retries: String
        var startsAt: String
        var phoneText: String
        var statusLabel: String

        init(code: String, name: String, payerText: String, retries: String, startsAt: String, phoneText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.payerText = payerText
            self.retries = retries
            self.startsAt = startsAt
            self.phoneText = phoneText
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentMappingView(_ item: AssessmentMapping) -> AssessmentMappingView {
        return AssessmentMappingView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            payerText: Kit.Text.truncate(item.payer, limit: 64),
            retries: String(item.retries),
            startsAt: String(item.startsAt),
            phoneText: Kit.Text.truncate(item.phone, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentMappingViews(_ items: [AssessmentMapping]) -> [AssessmentMappingView] {
        var views: [AssessmentMappingView] = []
        for item in items {
            views.append(toAssessmentMappingView(item))
        }
        return views
    }

    static func sumAssessmentMappingView(_ view: AssessmentMappingView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedRetries) + Double(parsedStartsAt)
    }
}
