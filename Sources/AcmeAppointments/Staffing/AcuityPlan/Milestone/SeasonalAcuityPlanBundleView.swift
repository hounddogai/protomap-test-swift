import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a seasonal acuity plan bundle.
    final class SeasonalAcuityPlanBundleView {
        var code: String
        var title: String
        var category: String
        var name: String
        var limitText: String
        var dosageMgText: String
        var ward: String
        var refills: String
        var version: String
        var priority: String
        var statusLabel: String

        init(code: String, title: String, category: String, name: String, limitText: String, dosageMgText: String, ward: String, refills: String, version: String, priority: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.category = category
            self.name = name
            self.limitText = limitText
            self.dosageMgText = dosageMgText
            self.ward = ward
            self.refills = refills
            self.version = version
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalAcuityPlanBundleView(_ item: SeasonalAcuityPlanBundle) -> SeasonalAcuityPlanBundleView {
        return SeasonalAcuityPlanBundleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            category: Kit.Text.truncate(item.category, limit: 64),
            name: item.name,
            limitText: String(item.limit),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            ward: Kit.Text.truncate(item.ward, limit: 120),
            refills: String(item.refills),
            version: String(item.version),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalAcuityPlanBundleViews(_ items: [SeasonalAcuityPlanBundle]) -> [SeasonalAcuityPlanBundleView] {
        var views: [SeasonalAcuityPlanBundleView] = []
        for item in items {
            views.append(toSeasonalAcuityPlanBundleView(item))
        }
        return views
    }

    static func sumSeasonalAcuityPlanBundleView(_ view: SeasonalAcuityPlanBundleView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedLimit) + parsedDosageMg + Double(parsedRefills)
    }
}
