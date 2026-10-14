import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential estimate.
    final class CredentialEstimateView {
        var code: String
        var label: String
        var name: String
        var summary: String
        var windowDays: String
        var limitText: String
        var ratio: String
        var statusLabel: String

        init(code: String, label: String, name: String, summary: String, windowDays: String, limitText: String, ratio: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.name = name
            self.summary = summary
            self.windowDays = windowDays
            self.limitText = limitText
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialEstimateView(_ item: CredentialEstimate) -> CredentialEstimateView {
        return CredentialEstimateView(
            code: item.code,
            label: item.label,
            name: item.name,
            summary: item.summary,
            windowDays: String(item.windowDays),
            limitText: String(item.limit),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialEstimateViews(_ items: [CredentialEstimate]) -> [CredentialEstimateView] {
        var views: [CredentialEstimateView] = []
        for item in items {
            views.append(toCredentialEstimateView(item))
        }
        return views
    }

    static func sumCredentialEstimateView(_ view: CredentialEstimateView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedLimit) + parsedRatio
    }
}
