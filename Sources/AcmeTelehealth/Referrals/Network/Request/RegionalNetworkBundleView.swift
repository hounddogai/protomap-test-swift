import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional network bundle.
    final class RegionalNetworkBundleView {
        var code: String
        var label: String
        var encounterID: String
        var refills: String
        var procedureCode: String
        var externalRef: String
        var category: String
        var summary: String
        var score: String
        var statusLabel: String

        init(code: String, label: String, encounterID: String, refills: String, procedureCode: String, externalRef: String, category: String, summary: String, score: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.refills = refills
            self.procedureCode = procedureCode
            self.externalRef = externalRef
            self.category = category
            self.summary = summary
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalNetworkBundleView(_ item: RegionalNetworkBundle) -> RegionalNetworkBundleView {
        return RegionalNetworkBundleView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            encounterID: item.encounterID,
            refills: String(item.refills),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            category: item.category,
            summary: Kit.Text.truncate(item.summary, limit: 120),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalNetworkBundleViews(_ items: [RegionalNetworkBundle]) -> [RegionalNetworkBundleView] {
        var views: [RegionalNetworkBundleView] = []
        for item in items {
            views.append(toRegionalNetworkBundleView(item))
        }
        return views
    }

    static func sumRegionalNetworkBundleView(_ view: RegionalNetworkBundleView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedRefills) + parsedScore
    }
}
