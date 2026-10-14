import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a global claim score.
    final class GlobalClaimScoreView {
        var code: String
        var nameText: String
        var retriesText: String
        var active: String
        var allergy: String
        var summaryText: String
        var ceilingText: String
        var statusLabel: String

        init(code: String, nameText: String, retriesText: String, active: String, allergy: String, summaryText: String, ceilingText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.retriesText = retriesText
            self.active = active
            self.allergy = allergy
            self.summaryText = summaryText
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalClaimScoreView(_ item: GlobalClaimScore) -> GlobalClaimScoreView {
        return GlobalClaimScoreView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            retriesText: String(item.retries),
            active: "\(item.active)",
            allergy: Kit.Text.truncate(item.allergy, limit: 120),
            summaryText: item.summary,
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalClaimScoreViews(_ items: [GlobalClaimScore]) -> [GlobalClaimScoreView] {
        var views: [GlobalClaimScoreView] = []
        for item in items {
            views.append(toGlobalClaimScoreView(item))
        }
        return views
    }

    static func sumGlobalClaimScoreView(_ view: GlobalClaimScoreView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedRetries) + parsedCeiling
    }
}
