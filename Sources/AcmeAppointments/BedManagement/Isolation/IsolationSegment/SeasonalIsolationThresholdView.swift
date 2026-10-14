import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a seasonal isolation threshold.
    final class SeasonalIsolationThresholdView {
        var code: String
        var label: String
        var margin: String
        var country: String
        var limit: String
        var clinicianIDText: String
        var ownerIDText: String
        var wardText: String
        var thresholdText: String
        var statusLabel: String

        init(code: String, label: String, margin: String, country: String, limit: String, clinicianIDText: String, ownerIDText: String, wardText: String, thresholdText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.margin = margin
            self.country = country
            self.limit = limit
            self.clinicianIDText = clinicianIDText
            self.ownerIDText = ownerIDText
            self.wardText = wardText
            self.thresholdText = thresholdText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalIsolationThresholdView(_ item: SeasonalIsolationThreshold) -> SeasonalIsolationThresholdView {
        return SeasonalIsolationThresholdView(
            code: item.code,
            label: item.label,
            margin: String(format: "%.2f", item.margin),
            country: item.country,
            limit: String(item.limit),
            clinicianIDText: item.clinicianID,
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 64),
            wardText: item.ward,
            thresholdText: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalIsolationThresholdViews(_ items: [SeasonalIsolationThreshold]) -> [SeasonalIsolationThresholdView] {
        var views: [SeasonalIsolationThresholdView] = []
        for item in items {
            views.append(toSeasonalIsolationThresholdView(item))
        }
        return views
    }

    static func sumSeasonalIsolationThresholdView(_ view: SeasonalIsolationThresholdView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedMargin + Double(parsedLimit) + parsedThreshold
    }
}
