import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure entry.
    final class ClosureEntryView {
        var code: String
        var labelText: String
        var category: String
        var copay: String
        var durationMinutes: String
        var facilityText: String
        var weight: String
        var statusLabel: String

        init(code: String, labelText: String, category: String, copay: String, durationMinutes: String, facilityText: String, weight: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.category = category
            self.copay = copay
            self.durationMinutes = durationMinutes
            self.facilityText = facilityText
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toClosureEntryView(_ item: ClosureEntry) -> ClosureEntryView {
        return ClosureEntryView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            category: Kit.Text.truncate(item.category, limit: 64),
            copay: String(format: "%.2f", item.copay),
            durationMinutes: String(item.durationMinutes),
            facilityText: Kit.Text.truncate(item.facility, limit: 64),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureEntryViews(_ items: [ClosureEntry]) -> [ClosureEntryView] {
        var views: [ClosureEntryView] = []
        for item in items {
            views.append(toClosureEntryView(item))
        }
        return views
    }

    static func sumClosureEntryView(_ view: ClosureEntryView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedCopay + Double(parsedDurationMinutes) + parsedWeight
    }
}
