import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a global result preference.
    final class GlobalResultPreferenceView {
        var codeText: String
        var label: String
        var cost: String
        var archivedText: String
        var unit: String
        var countryText: String
        var encounterID: String
        var statusLabel: String

        init(codeText: String, label: String, cost: String, archivedText: String, unit: String, countryText: String, encounterID: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.cost = cost
            self.archivedText = archivedText
            self.unit = unit
            self.countryText = countryText
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalResultPreferenceView(_ item: GlobalResultPreference) -> GlobalResultPreferenceView {
        return GlobalResultPreferenceView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            cost: String(format: "%.2f", item.cost),
            archivedText: "\(item.archived)",
            unit: item.unit,
            countryText: Kit.Text.truncate(item.country, limit: 80),
            encounterID: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalResultPreferenceViews(_ items: [GlobalResultPreference]) -> [GlobalResultPreferenceView] {
        var views: [GlobalResultPreferenceView] = []
        for item in items {
            views.append(toGlobalResultPreferenceView(item))
        }
        return views
    }

    static func sumGlobalResultPreferenceView(_ view: GlobalResultPreferenceView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCost
    }
}
