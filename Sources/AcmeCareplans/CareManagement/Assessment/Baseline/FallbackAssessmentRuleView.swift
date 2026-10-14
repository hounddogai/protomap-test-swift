import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a fallback assessment rule.
    final class FallbackAssessmentRuleView {
        var code: String
        var name: String
        var locale: String
        var floorValue: String
        var versionText: String
        var allergy: String
        var rate: String
        var externalRef: String
        var marginText: String
        var updatedAtText: String
        var statusLabel: String

        init(code: String, name: String, locale: String, floorValue: String, versionText: String, allergy: String, rate: String, externalRef: String, marginText: String, updatedAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.locale = locale
            self.floorValue = floorValue
            self.versionText = versionText
            self.allergy = allergy
            self.rate = rate
            self.externalRef = externalRef
            self.marginText = marginText
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackAssessmentRuleView(_ item: FallbackAssessmentRule) -> FallbackAssessmentRuleView {
        return FallbackAssessmentRuleView(
            code: item.code,
            name: item.name,
            locale: item.locale,
            floorValue: String(format: "%.2f", item.floorValue),
            versionText: String(item.version),
            allergy: item.allergy,
            rate: String(format: "%.2f", item.rate),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 120),
            marginText: String(format: "%.2f", item.margin),
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackAssessmentRuleViews(_ items: [FallbackAssessmentRule]) -> [FallbackAssessmentRuleView] {
        var views: [FallbackAssessmentRuleView] = []
        for item in items {
            views.append(toFallbackAssessmentRuleView(item))
        }
        return views
    }

    static func sumFallbackAssessmentRuleView(_ view: FallbackAssessmentRuleView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedFloorValue + Double(parsedVersion) + parsedRate
    }
}
