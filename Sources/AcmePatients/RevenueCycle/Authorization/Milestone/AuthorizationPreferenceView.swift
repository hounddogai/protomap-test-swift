import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization preference.
    final class AuthorizationPreferenceView {
        var code: String
        var label: String
        var floorValue: String
        var graceDays: String
        var dosageMgText: String
        var statusLabel: String

        init(code: String, label: String, floorValue: String, graceDays: String, dosageMgText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.graceDays = graceDays
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationPreferenceView(_ item: AuthorizationPreference) -> AuthorizationPreferenceView {
        return AuthorizationPreferenceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            floorValue: String(format: "%.2f", item.floorValue),
            graceDays: String(item.graceDays),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationPreferenceViews(_ items: [AuthorizationPreference]) -> [AuthorizationPreferenceView] {
        var views: [AuthorizationPreferenceView] = []
        for item in items {
            views.append(toAuthorizationPreferenceView(item))
        }
        return views
    }

    static func sumAuthorizationPreferenceView(_ view: AuthorizationPreferenceView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedFloorValue + Double(parsedGraceDays) + parsedDosageMg
    }
}
