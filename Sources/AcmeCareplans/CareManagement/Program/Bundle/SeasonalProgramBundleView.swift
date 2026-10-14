import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a seasonal program bundle.
    final class SeasonalProgramBundleView {
        var codeText: String
        var titleText: String
        var limit: String
        var descriptionText: String
        var active: String
        var unit: String
        var facility: String
        var payer: String
        var statusLabel: String

        init(codeText: String, titleText: String, limit: String, descriptionText: String, active: String, unit: String, facility: String, payer: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.limit = limit
            self.descriptionText = descriptionText
            self.active = active
            self.unit = unit
            self.facility = facility
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalProgramBundleView(_ item: SeasonalProgramBundle) -> SeasonalProgramBundleView {
        return SeasonalProgramBundleView(
            codeText: item.code,
            titleText: item.title,
            limit: String(item.limit),
            descriptionText: Kit.Text.truncate(item.description, limit: 40),
            active: "\(item.active)",
            unit: item.unit,
            facility: item.facility,
            payer: Kit.Text.truncate(item.payer, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalProgramBundleViews(_ items: [SeasonalProgramBundle]) -> [SeasonalProgramBundleView] {
        var views: [SeasonalProgramBundleView] = []
        for item in items {
            views.append(toSeasonalProgramBundleView(item))
        }
        return views
    }

    static func sumSeasonalProgramBundleView(_ view: SeasonalProgramBundleView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedLimit)
    }
}
