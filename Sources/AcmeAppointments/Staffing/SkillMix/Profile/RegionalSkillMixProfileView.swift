import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional skill mix profile.
    final class RegionalSkillMixProfileView {
        var code: String
        var name: String
        var visibleText: String
        var externalRef: String
        var procedureCode: String
        var segmentText: String
        var amount: String
        var statusLabel: String

        init(code: String, name: String, visibleText: String, externalRef: String, procedureCode: String, segmentText: String, amount: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visibleText = visibleText
            self.externalRef = externalRef
            self.procedureCode = procedureCode
            self.segmentText = segmentText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalSkillMixProfileView(_ item: RegionalSkillMixProfile) -> RegionalSkillMixProfileView {
        return RegionalSkillMixProfileView(
            code: item.code,
            name: item.name,
            visibleText: "\(item.visible)",
            externalRef: item.externalRef,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            segmentText: Kit.Text.truncate(item.segment, limit: 40),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalSkillMixProfileViews(_ items: [RegionalSkillMixProfile]) -> [RegionalSkillMixProfileView] {
        var views: [RegionalSkillMixProfileView] = []
        for item in items {
            views.append(toRegionalSkillMixProfileView(item))
        }
        return views
    }

    static func sumRegionalSkillMixProfileView(_ view: RegionalSkillMixProfileView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
