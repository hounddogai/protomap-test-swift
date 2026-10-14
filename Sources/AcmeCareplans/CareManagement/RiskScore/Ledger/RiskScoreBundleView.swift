import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score bundle.
    final class RiskScoreBundleView {
        var code: String
        var nameText: String
        var dosageMgText: String
        var visitMinutes: String
        var categoryText: String
        var floorValue: String
        var title: String
        var statusLabel: String

        init(code: String, nameText: String, dosageMgText: String, visitMinutes: String, categoryText: String, floorValue: String, title: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.dosageMgText = dosageMgText
            self.visitMinutes = visitMinutes
            self.categoryText = categoryText
            self.floorValue = floorValue
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreBundleView(_ item: RiskScoreBundle) -> RiskScoreBundleView {
        return RiskScoreBundleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            visitMinutes: String(item.visitMinutes),
            categoryText: Kit.Text.truncate(item.category, limit: 64),
            floorValue: String(format: "%.2f", item.floorValue),
            title: Kit.Text.truncate(item.title, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreBundleViews(_ items: [RiskScoreBundle]) -> [RiskScoreBundleView] {
        var views: [RiskScoreBundleView] = []
        for item in items {
            views.append(toRiskScoreBundleView(item))
        }
        return views
    }

    static func sumRiskScoreBundleView(_ view: RiskScoreBundleView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedDosageMg + Double(parsedVisitMinutes) + parsedFloorValue
    }
}
