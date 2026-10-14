import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a strict dispense target.
    final class StrictDispenseTargetView {
        var code: String
        var label: String
        var updatedAt: String
        var active: String
        var phoneText: String
        var version: String
        var localeText: String
        var statusLabel: String

        init(code: String, label: String, updatedAt: String, active: String, phoneText: String, version: String, localeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.active = active
            self.phoneText = phoneText
            self.version = version
            self.localeText = localeText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictDispenseTargetView(_ item: StrictDispenseTarget) -> StrictDispenseTargetView {
        return StrictDispenseTargetView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            updatedAt: String(item.updatedAt),
            active: "\(item.active)",
            phoneText: item.phone,
            version: String(item.version),
            localeText: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictDispenseTargetViews(_ items: [StrictDispenseTarget]) -> [StrictDispenseTargetView] {
        var views: [StrictDispenseTargetView] = []
        for item in items {
            views.append(toStrictDispenseTargetView(item))
        }
        return views
    }

    static func sumStrictDispenseTargetView(_ view: StrictDispenseTargetView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedVersion)
    }
}
