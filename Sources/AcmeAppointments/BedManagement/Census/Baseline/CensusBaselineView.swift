import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census baseline.
    final class CensusBaselineView {
        var code: String
        var label: String
        var titleText: String
        var clinicianID: String
        var windowDays: String
        var budget: String
        var margin: String
        var pinned: String
        var statusLabel: String

        init(code: String, label: String, titleText: String, clinicianID: String, windowDays: String, budget: String, margin: String, pinned: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.titleText = titleText
            self.clinicianID = clinicianID
            self.windowDays = windowDays
            self.budget = budget
            self.margin = margin
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toCensusBaselineView(_ item: CensusBaseline) -> CensusBaselineView {
        return CensusBaselineView(
            code: item.code,
            label: item.label,
            titleText: item.title,
            clinicianID: item.clinicianID,
            windowDays: String(item.windowDays),
            budget: String(format: "%.2f", item.budget),
            margin: String(format: "%.2f", item.margin),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusBaselineViews(_ items: [CensusBaseline]) -> [CensusBaselineView] {
        var views: [CensusBaselineView] = []
        for item in items {
            views.append(toCensusBaselineView(item))
        }
        return views
    }

    static func sumCensusBaselineView(_ view: CensusBaselineView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedWindowDays) + parsedBudget + parsedMargin
    }
}
