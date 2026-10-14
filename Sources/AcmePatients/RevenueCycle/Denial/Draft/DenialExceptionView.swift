import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial exception.
    final class DenialExceptionView {
        var code: String
        var title: String
        var expiresAt: String
        var updatedAt: String
        var descriptionText: String
        var windowDays: String
        var segment: String
        var unit: String
        var active: String
        var statusLabel: String

        init(code: String, title: String, expiresAt: String, updatedAt: String, descriptionText: String, windowDays: String, segment: String, unit: String, active: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
            self.descriptionText = descriptionText
            self.windowDays = windowDays
            self.segment = segment
            self.unit = unit
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toDenialExceptionView(_ item: DenialException) -> DenialExceptionView {
        return DenialExceptionView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 80),
            expiresAt: String(item.expiresAt),
            updatedAt: String(item.updatedAt),
            descriptionText: item.description,
            windowDays: String(item.windowDays),
            segment: item.segment,
            unit: item.unit,
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialExceptionViews(_ items: [DenialException]) -> [DenialExceptionView] {
        var views: [DenialExceptionView] = []
        for item in items {
            views.append(toDenialExceptionView(item))
        }
        return views
    }

    static func sumDenialExceptionView(_ view: DenialExceptionView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedUpdatedAt) + Double(parsedWindowDays)
    }
}
