import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation override.
    final class IsolationOverrideView {
        var code: String
        var title: String
        var durationMinutes: String
        var retries: String
        var approved: String
        var weight: String
        var allergy: String
        var statusLabel: String

        init(code: String, title: String, durationMinutes: String, retries: String, approved: String, weight: String, allergy: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.retries = retries
            self.approved = approved
            self.weight = weight
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationOverrideView(_ item: IsolationOverride) -> IsolationOverrideView {
        return IsolationOverrideView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            durationMinutes: String(item.durationMinutes),
            retries: String(item.retries),
            approved: "\(item.approved)",
            weight: String(format: "%.2f", item.weight),
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationOverrideViews(_ items: [IsolationOverride]) -> [IsolationOverrideView] {
        var views: [IsolationOverrideView] = []
        for item in items {
            views.append(toIsolationOverrideView(item))
        }
        return views
    }

    static func sumIsolationOverrideView(_ view: IsolationOverrideView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedRetries) + parsedWeight
    }
}
