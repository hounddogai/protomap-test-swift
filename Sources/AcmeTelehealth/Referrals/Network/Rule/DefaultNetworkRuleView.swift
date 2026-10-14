import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a default network rule.
    final class DefaultNetworkRuleView {
        var code: String
        var labelText: String
        var sequence: String
        var patientRef: String
        var durationMinutesText: String
        var countryText: String
        var score: String
        var timezoneText: String
        var statusLabel: String

        init(code: String, labelText: String, sequence: String, patientRef: String, durationMinutesText: String, countryText: String, score: String, timezoneText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.sequence = sequence
            self.patientRef = patientRef
            self.durationMinutesText = durationMinutesText
            self.countryText = countryText
            self.score = score
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultNetworkRuleView(_ item: DefaultNetworkRule) -> DefaultNetworkRuleView {
        return DefaultNetworkRuleView(
            code: item.code,
            labelText: item.label,
            sequence: String(item.sequence),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            durationMinutesText: String(item.durationMinutes),
            countryText: item.country,
            score: String(format: "%.2f", item.score),
            timezoneText: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultNetworkRuleViews(_ items: [DefaultNetworkRule]) -> [DefaultNetworkRuleView] {
        var views: [DefaultNetworkRuleView] = []
        for item in items {
            views.append(toDefaultNetworkRuleView(item))
        }
        return views
    }

    static func sumDefaultNetworkRuleView(_ view: DefaultNetworkRuleView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedSequence) + Double(parsedDurationMinutes) + parsedScore
    }
}
