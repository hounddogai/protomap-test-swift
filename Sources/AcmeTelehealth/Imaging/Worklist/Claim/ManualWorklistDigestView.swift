import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a manual worklist digest.
    final class ManualWorklistDigestView {
        var code: String
        var name: String
        var phone: String
        var budget: String
        var durationMinutes: String
        var title: String
        var margin: String
        var localeText: String
        var statusLabel: String

        init(code: String, name: String, phone: String, budget: String, durationMinutes: String, title: String, margin: String, localeText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.phone = phone
            self.budget = budget
            self.durationMinutes = durationMinutes
            self.title = title
            self.margin = margin
            self.localeText = localeText
            self.statusLabel = statusLabel
        }
    }

    static func toManualWorklistDigestView(_ item: ManualWorklistDigest) -> ManualWorklistDigestView {
        return ManualWorklistDigestView(
            code: item.code,
            name: item.name,
            phone: item.phone,
            budget: String(format: "%.2f", item.budget),
            durationMinutes: String(item.durationMinutes),
            title: Kit.Text.truncate(item.title, limit: 40),
            margin: String(format: "%.2f", item.margin),
            localeText: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualWorklistDigestViews(_ items: [ManualWorklistDigest]) -> [ManualWorklistDigestView] {
        var views: [ManualWorklistDigestView] = []
        for item in items {
            views.append(toManualWorklistDigestView(item))
        }
        return views
    }

    static func sumManualWorklistDigestView(_ view: ManualWorklistDigestView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedBudget + Double(parsedDurationMinutes) + parsedMargin
    }
}
