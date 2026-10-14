import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a seasonal charge estimate.
    final class SeasonalChargeEstimateView {
        var codeText: String
        var name: String
        var diagnosisCode: String
        var priority: String
        var windowDays: String
        var clinicianIDText: String
        var archivedText: String
        var visible: String
        var costText: String
        var title: String
        var bedText: String
        var statusLabel: String

        init(codeText: String, name: String, diagnosisCode: String, priority: String, windowDays: String, clinicianIDText: String, archivedText: String, visible: String, costText: String, title: String, bedText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.priority = priority
            self.windowDays = windowDays
            self.clinicianIDText = clinicianIDText
            self.archivedText = archivedText
            self.visible = visible
            self.costText = costText
            self.title = title
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalChargeEstimateView(_ item: SeasonalChargeEstimate) -> SeasonalChargeEstimateView {
        return SeasonalChargeEstimateView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            priority: String(item.priority),
            windowDays: String(item.windowDays),
            clinicianIDText: item.clinicianID,
            archivedText: "\(item.archived)",
            visible: "\(item.visible)",
            costText: String(format: "%.2f", item.cost),
            title: Kit.Text.truncate(item.title, limit: 80),
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalChargeEstimateViews(_ items: [SeasonalChargeEstimate]) -> [SeasonalChargeEstimateView] {
        var views: [SeasonalChargeEstimateView] = []
        for item in items {
            views.append(toSeasonalChargeEstimateView(item))
        }
        return views
    }

    static func sumSeasonalChargeEstimateView(_ view: SeasonalChargeEstimateView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedPriority) + Double(parsedWindowDays) + parsedCost
    }
}
