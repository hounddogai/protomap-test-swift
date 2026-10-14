import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a manual read estimate.
    final class ManualReadEstimateView {
        var codeText: String
        var title: String
        var phone: String
        var graceDays: String
        var currency: String
        var statusLabel: String

        init(codeText: String, title: String, phone: String, graceDays: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.phone = phone
            self.graceDays = graceDays
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toManualReadEstimateView(_ item: ManualReadEstimate) -> ManualReadEstimateView {
        return ManualReadEstimateView(
            codeText: item.code,
            title: item.title,
            phone: item.phone,
            graceDays: String(item.graceDays),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualReadEstimateViews(_ items: [ManualReadEstimate]) -> [ManualReadEstimateView] {
        var views: [ManualReadEstimateView] = []
        for item in items {
            views.append(toManualReadEstimateView(item))
        }
        return views
    }

    static func sumManualReadEstimateView(_ view: ManualReadEstimateView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
