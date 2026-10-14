import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a manual cleaning window.
    final class ManualCleaningWindowView {
        var code: String
        var label: String
        var phoneText: String
        var attempts: String
        var limit: String
        var statusLabel: String

        init(code: String, label: String, phoneText: String, attempts: String, limit: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.phoneText = phoneText
            self.attempts = attempts
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toManualCleaningWindowView(_ item: ManualCleaningWindow) -> ManualCleaningWindowView {
        return ManualCleaningWindowView(
            code: item.code,
            label: item.label,
            phoneText: item.phone,
            attempts: String(item.attempts),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCleaningWindowViews(_ items: [ManualCleaningWindow]) -> [ManualCleaningWindowView] {
        var views: [ManualCleaningWindowView] = []
        for item in items {
            views.append(toManualCleaningWindowView(item))
        }
        return views
    }

    static func sumManualCleaningWindowView(_ view: ManualCleaningWindowView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedAttempts) + Double(parsedLimit)
    }
}
