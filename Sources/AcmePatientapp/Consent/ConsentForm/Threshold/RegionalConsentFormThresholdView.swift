import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional consent form threshold.
    final class RegionalConsentFormThresholdView {
        var codeText: String
        var titleText: String
        var activeText: String
        var allergy: String
        var clinicianIDText: String
        var limitText: String
        var locale: String
        var externalRef: String
        var sequenceText: String
        var bed: String
        var rate: String
        var statusLabel: String

        init(codeText: String, titleText: String, activeText: String, allergy: String, clinicianIDText: String, limitText: String, locale: String, externalRef: String, sequenceText: String, bed: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.activeText = activeText
            self.allergy = allergy
            self.clinicianIDText = clinicianIDText
            self.limitText = limitText
            self.locale = locale
            self.externalRef = externalRef
            self.sequenceText = sequenceText
            self.bed = bed
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalConsentFormThresholdView(_ item: RegionalConsentFormThreshold) -> RegionalConsentFormThresholdView {
        return RegionalConsentFormThresholdView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            activeText: "\(item.active)",
            allergy: item.allergy,
            clinicianIDText: item.clinicianID,
            limitText: String(item.limit),
            locale: item.locale,
            externalRef: item.externalRef,
            sequenceText: String(item.sequence),
            bed: item.bed,
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalConsentFormThresholdViews(_ items: [RegionalConsentFormThreshold]) -> [RegionalConsentFormThresholdView] {
        var views: [RegionalConsentFormThresholdView] = []
        for item in items {
            views.append(toRegionalConsentFormThresholdView(item))
        }
        return views
    }

    static func sumRegionalConsentFormThresholdView(_ view: RegionalConsentFormThresholdView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedLimit) + Double(parsedSequence) + parsedRate
    }
}
