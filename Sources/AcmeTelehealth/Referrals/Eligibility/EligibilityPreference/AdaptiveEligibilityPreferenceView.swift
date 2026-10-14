import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a adaptive eligibility preference.
    final class AdaptiveEligibilityPreferenceView {
        var codeText: String
        var nameText: String
        var rate: String
        var maximum: String
        var country: String
        var sequenceText: String
        var updatedAtText: String
        var bedText: String
        var statusLabel: String

        init(codeText: String, nameText: String, rate: String, maximum: String, country: String, sequenceText: String, updatedAtText: String, bedText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.rate = rate
            self.maximum = maximum
            self.country = country
            self.sequenceText = sequenceText
            self.updatedAtText = updatedAtText
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveEligibilityPreferenceView(_ item: AdaptiveEligibilityPreference) -> AdaptiveEligibilityPreferenceView {
        return AdaptiveEligibilityPreferenceView(
            codeText: item.code,
            nameText: item.name,
            rate: String(format: "%.2f", item.rate),
            maximum: String(format: "%.2f", item.maximum),
            country: item.country,
            sequenceText: String(item.sequence),
            updatedAtText: String(item.updatedAt),
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveEligibilityPreferenceViews(_ items: [AdaptiveEligibilityPreference]) -> [AdaptiveEligibilityPreferenceView] {
        var views: [AdaptiveEligibilityPreferenceView] = []
        for item in items {
            views.append(toAdaptiveEligibilityPreferenceView(item))
        }
        return views
    }

    static func sumAdaptiveEligibilityPreferenceView(_ view: AdaptiveEligibilityPreferenceView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedRate + parsedMaximum + Double(parsedSequence)
    }
}
