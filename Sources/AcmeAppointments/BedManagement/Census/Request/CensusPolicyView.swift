import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census policy.
    final class CensusPolicyView {
        var code: String
        var name: String
        var windowDays: String
        var maximum: String
        var limitText: String
        var approved: String
        var statusLabel: String

        init(code: String, name: String, windowDays: String, maximum: String, limitText: String, approved: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.maximum = maximum
            self.limitText = limitText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toCensusPolicyView(_ item: CensusPolicy) -> CensusPolicyView {
        return CensusPolicyView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            windowDays: String(item.windowDays),
            maximum: String(format: "%.2f", item.maximum),
            limitText: String(item.limit),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusPolicyViews(_ items: [CensusPolicy]) -> [CensusPolicyView] {
        var views: [CensusPolicyView] = []
        for item in items {
            views.append(toCensusPolicyView(item))
        }
        return views
    }

    static func sumCensusPolicyView(_ view: CensusPolicyView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedWindowDays) + parsedMaximum + Double(parsedLimit)
    }
}
