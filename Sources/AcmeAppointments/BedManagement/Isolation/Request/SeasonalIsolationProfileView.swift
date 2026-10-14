import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a seasonal isolation profile.
    final class SeasonalIsolationProfileView {
        var code: String
        var labelText: String
        var specialty: String
        var title: String
        var clinicianIDText: String
        var active: String
        var name: String
        var approved: String
        var ceiling: String
        var statusLabel: String

        init(code: String, labelText: String, specialty: String, title: String, clinicianIDText: String, active: String, name: String, approved: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.specialty = specialty
            self.title = title
            self.clinicianIDText = clinicianIDText
            self.active = active
            self.name = name
            self.approved = approved
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalIsolationProfileView(_ item: SeasonalIsolationProfile) -> SeasonalIsolationProfileView {
        return SeasonalIsolationProfileView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            specialty: item.specialty,
            title: item.title,
            clinicianIDText: item.clinicianID,
            active: "\(item.active)",
            name: item.name,
            approved: "\(item.approved)",
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalIsolationProfileViews(_ items: [SeasonalIsolationProfile]) -> [SeasonalIsolationProfileView] {
        var views: [SeasonalIsolationProfileView] = []
        for item in items {
            views.append(toSeasonalIsolationProfileView(item))
        }
        return views
    }

    static func sumSeasonalIsolationProfileView(_ view: SeasonalIsolationProfileView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCeiling
    }
}
