import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional network score.
    final class RegionalNetworkScoreView {
        var codeText: String
        var name: String
        var unit: String
        var clinicianIDText: String
        var rateText: String
        var notes: String
        var statusLabel: String

        init(codeText: String, name: String, unit: String, clinicianIDText: String, rateText: String, notes: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.unit = unit
            self.clinicianIDText = clinicianIDText
            self.rateText = rateText
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalNetworkScoreView(_ item: RegionalNetworkScore) -> RegionalNetworkScoreView {
        return RegionalNetworkScoreView(
            codeText: item.code,
            name: item.name,
            unit: item.unit,
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 64),
            rateText: String(format: "%.2f", item.rate),
            notes: Kit.Text.truncate(item.notes, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalNetworkScoreViews(_ items: [RegionalNetworkScore]) -> [RegionalNetworkScoreView] {
        var views: [RegionalNetworkScoreView] = []
        for item in items {
            views.append(toRegionalNetworkScoreView(item))
        }
        return views
    }

    static func sumRegionalNetworkScoreView(_ view: RegionalNetworkScoreView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
