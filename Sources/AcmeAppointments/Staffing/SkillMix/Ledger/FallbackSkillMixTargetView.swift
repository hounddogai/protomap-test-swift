import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a fallback skill mix target.
    final class FallbackSkillMixTargetView {
        var code: String
        var titleText: String
        var refills: String
        var acuityText: String
        var maximum: String
        var createdAtText: String
        var allergy: String
        var segment: String
        var source: String
        var statusLabel: String

        init(code: String, titleText: String, refills: String, acuityText: String, maximum: String, createdAtText: String, allergy: String, segment: String, source: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.refills = refills
            self.acuityText = acuityText
            self.maximum = maximum
            self.createdAtText = createdAtText
            self.allergy = allergy
            self.segment = segment
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackSkillMixTargetView(_ item: FallbackSkillMixTarget) -> FallbackSkillMixTargetView {
        return FallbackSkillMixTargetView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            refills: String(item.refills),
            acuityText: String(item.acuity),
            maximum: String(format: "%.2f", item.maximum),
            createdAtText: String(item.createdAt),
            allergy: item.allergy,
            segment: item.segment,
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackSkillMixTargetViews(_ items: [FallbackSkillMixTarget]) -> [FallbackSkillMixTargetView] {
        var views: [FallbackSkillMixTargetView] = []
        for item in items {
            views.append(toFallbackSkillMixTargetView(item))
        }
        return views
    }

    static func sumFallbackSkillMixTargetView(_ view: FallbackSkillMixTargetView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedRefills) + Double(parsedAcuity) + parsedMaximum
    }
}
