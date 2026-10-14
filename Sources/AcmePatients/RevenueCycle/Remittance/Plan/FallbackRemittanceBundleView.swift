import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a fallback remittance bundle.
    final class FallbackRemittanceBundleView {
        var codeText: String
        var labelText: String
        var encounterID: String
        var clinicianID: String
        var floorValueText: String
        var title: String
        var limitText: String
        var category: String
        var timezone: String
        var rate: String
        var statusLabel: String

        init(codeText: String, labelText: String, encounterID: String, clinicianID: String, floorValueText: String, title: String, limitText: String, category: String, timezone: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.encounterID = encounterID
            self.clinicianID = clinicianID
            self.floorValueText = floorValueText
            self.title = title
            self.limitText = limitText
            self.category = category
            self.timezone = timezone
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackRemittanceBundleView(_ item: FallbackRemittanceBundle) -> FallbackRemittanceBundleView {
        return FallbackRemittanceBundleView(
            codeText: item.code,
            labelText: item.label,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 40),
            clinicianID: item.clinicianID,
            floorValueText: String(format: "%.2f", item.floorValue),
            title: Kit.Text.truncate(item.title, limit: 64),
            limitText: String(item.limit),
            category: Kit.Text.truncate(item.category, limit: 80),
            timezone: item.timezone,
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackRemittanceBundleViews(_ items: [FallbackRemittanceBundle]) -> [FallbackRemittanceBundleView] {
        var views: [FallbackRemittanceBundleView] = []
        for item in items {
            views.append(toFallbackRemittanceBundleView(item))
        }
        return views
    }

    static func sumFallbackRemittanceBundleView(_ view: FallbackRemittanceBundleView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedFloorValue + Double(parsedLimit) + parsedRate
    }
}
