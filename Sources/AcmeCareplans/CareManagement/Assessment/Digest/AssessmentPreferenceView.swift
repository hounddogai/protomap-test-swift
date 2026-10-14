import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment preference.
    final class AssessmentPreferenceView {
        var code: String
        var title: String
        var active: String
        var cost: String
        var acuityText: String
        var version: String
        var graceDays: String
        var startsAt: String
        var refills: String
        var channel: String
        var payerText: String
        var statusLabel: String

        init(code: String, title: String, active: String, cost: String, acuityText: String, version: String, graceDays: String, startsAt: String, refills: String, channel: String, payerText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.active = active
            self.cost = cost
            self.acuityText = acuityText
            self.version = version
            self.graceDays = graceDays
            self.startsAt = startsAt
            self.refills = refills
            self.channel = channel
            self.payerText = payerText
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentPreferenceView(_ item: AssessmentPreference) -> AssessmentPreferenceView {
        return AssessmentPreferenceView(
            code: item.code,
            title: item.title,
            active: "\(item.active)",
            cost: String(format: "%.2f", item.cost),
            acuityText: String(item.acuity),
            version: String(item.version),
            graceDays: String(item.graceDays),
            startsAt: String(item.startsAt),
            refills: String(item.refills),
            channel: item.channel,
            payerText: Kit.Text.truncate(item.payer, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentPreferenceViews(_ items: [AssessmentPreference]) -> [AssessmentPreferenceView] {
        var views: [AssessmentPreferenceView] = []
        for item in items {
            views.append(toAssessmentPreferenceView(item))
        }
        return views
    }

    static func sumAssessmentPreferenceView(_ view: AssessmentPreferenceView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedCost + Double(parsedAcuity) + Double(parsedVersion)
    }
}
