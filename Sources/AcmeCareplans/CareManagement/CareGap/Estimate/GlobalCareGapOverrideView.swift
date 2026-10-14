import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global care gap override.
    final class GlobalCareGapOverrideView {
        var code: String
        var name: String
        var revision: String
        var costText: String
        var margin: String
        var limitText: String
        var archived: String
        var locale: String
        var score: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, name: String, revision: String, costText: String, margin: String, limitText: String, archived: String, locale: String, score: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.revision = revision
            self.costText = costText
            self.margin = margin
            self.limitText = limitText
            self.archived = archived
            self.locale = locale
            self.score = score
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCareGapOverrideView(_ item: GlobalCareGapOverride) -> GlobalCareGapOverrideView {
        return GlobalCareGapOverrideView(
            code: item.code,
            name: item.name,
            revision: String(item.revision),
            costText: String(format: "%.2f", item.cost),
            margin: String(format: "%.2f", item.margin),
            limitText: String(item.limit),
            archived: "\(item.archived)",
            locale: Kit.Text.truncate(item.locale, limit: 120),
            score: String(format: "%.2f", item.score),
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCareGapOverrideViews(_ items: [GlobalCareGapOverride]) -> [GlobalCareGapOverrideView] {
        var views: [GlobalCareGapOverrideView] = []
        for item in items {
            views.append(toGlobalCareGapOverrideView(item))
        }
        return views
    }

    static func sumGlobalCareGapOverrideView(_ view: GlobalCareGapOverrideView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedRevision) + parsedCost + parsedMargin
    }
}
