import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a regional statement baseline.
    final class RegionalStatementBaselineView {
        var code: String
        var label: String
        var encounterID: String
        var active: String
        var copay: String
        var ward: String
        var statusLabel: String

        init(code: String, label: String, encounterID: String, active: String, copay: String, ward: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.active = active
            self.copay = copay
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalStatementBaselineView(_ item: RegionalStatementBaseline) -> RegionalStatementBaselineView {
        return RegionalStatementBaselineView(
            code: item.code,
            label: item.label,
            encounterID: item.encounterID,
            active: "\(item.active)",
            copay: String(format: "%.2f", item.copay),
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalStatementBaselineViews(_ items: [RegionalStatementBaseline]) -> [RegionalStatementBaselineView] {
        var views: [RegionalStatementBaselineView] = []
        for item in items {
            views.append(toRegionalStatementBaselineView(item))
        }
        return views
    }

    static func sumRegionalStatementBaselineView(_ view: RegionalStatementBaselineView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
