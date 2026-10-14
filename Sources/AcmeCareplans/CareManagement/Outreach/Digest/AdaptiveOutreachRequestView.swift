import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a adaptive outreach request.
    final class AdaptiveOutreachRequestView {
        var code: String
        var title: String
        var copay: String
        var descriptionText: String
        var windowDays: String
        var currency: String
        var statusLabel: String

        init(code: String, title: String, copay: String, descriptionText: String, windowDays: String, currency: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.copay = copay
            self.descriptionText = descriptionText
            self.windowDays = windowDays
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveOutreachRequestView(_ item: AdaptiveOutreachRequest) -> AdaptiveOutreachRequestView {
        return AdaptiveOutreachRequestView(
            code: item.code,
            title: item.title,
            copay: String(format: "%.2f", item.copay),
            descriptionText: Kit.Text.truncate(item.description, limit: 80),
            windowDays: String(item.windowDays),
            currency: Kit.Text.truncate(item.currency, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveOutreachRequestViews(_ items: [AdaptiveOutreachRequest]) -> [AdaptiveOutreachRequestView] {
        var views: [AdaptiveOutreachRequestView] = []
        for item in items {
            views.append(toAdaptiveOutreachRequestView(item))
        }
        return views
    }

    static func sumAdaptiveOutreachRequestView(_ view: AdaptiveOutreachRequestView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedCopay + Double(parsedWindowDays)
    }
}
