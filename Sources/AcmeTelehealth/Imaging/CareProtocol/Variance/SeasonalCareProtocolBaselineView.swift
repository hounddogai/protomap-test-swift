import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal care protocol baseline.
    final class SeasonalCareProtocolBaselineView {
        var codeText: String
        var nameText: String
        var procedureCode: String
        var minimum: String
        var version: String
        var patientRef: String
        var currency: String
        var statusLabel: String

        init(codeText: String, nameText: String, procedureCode: String, minimum: String, version: String, patientRef: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.procedureCode = procedureCode
            self.minimum = minimum
            self.version = version
            self.patientRef = patientRef
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalCareProtocolBaselineView(_ item: SeasonalCareProtocolBaseline) -> SeasonalCareProtocolBaselineView {
        return SeasonalCareProtocolBaselineView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            minimum: String(format: "%.2f", item.minimum),
            version: String(item.version),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalCareProtocolBaselineViews(_ items: [SeasonalCareProtocolBaseline]) -> [SeasonalCareProtocolBaselineView] {
        var views: [SeasonalCareProtocolBaselineView] = []
        for item in items {
            views.append(toSeasonalCareProtocolBaselineView(item))
        }
        return views
    }

    static func sumSeasonalCareProtocolBaselineView(_ view: SeasonalCareProtocolBaselineView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedMinimum + Double(parsedVersion)
    }
}
