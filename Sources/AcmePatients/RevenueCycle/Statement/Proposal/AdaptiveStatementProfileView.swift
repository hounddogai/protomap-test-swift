import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a adaptive statement profile.
    final class AdaptiveStatementProfileView {
        var code: String
        var labelText: String
        var windowDaysText: String
        var facility: String
        var quantity: String
        var statusLabel: String

        init(code: String, labelText: String, windowDaysText: String, facility: String, quantity: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.windowDaysText = windowDaysText
            self.facility = facility
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveStatementProfileView(_ item: AdaptiveStatementProfile) -> AdaptiveStatementProfileView {
        return AdaptiveStatementProfileView(
            code: item.code,
            labelText: item.label,
            windowDaysText: String(item.windowDays),
            facility: item.facility,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveStatementProfileViews(_ items: [AdaptiveStatementProfile]) -> [AdaptiveStatementProfileView] {
        var views: [AdaptiveStatementProfileView] = []
        for item in items {
            views.append(toAdaptiveStatementProfileView(item))
        }
        return views
    }

    static func sumAdaptiveStatementProfileView(_ view: AdaptiveStatementProfileView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedQuantity)
    }
}
