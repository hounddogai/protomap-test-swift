import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift tier.
    final class ShiftTierView {
        var code: String
        var name: String
        var durationMinutesText: String
        var externalRefText: String
        var archived: String
        var minimum: String
        var phoneText: String
        var refillsText: String
        var statusLabel: String

        init(code: String, name: String, durationMinutesText: String, externalRefText: String, archived: String, minimum: String, phoneText: String, refillsText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.durationMinutesText = durationMinutesText
            self.externalRefText = externalRefText
            self.archived = archived
            self.minimum = minimum
            self.phoneText = phoneText
            self.refillsText = refillsText
            self.statusLabel = statusLabel
        }
    }

    static func toShiftTierView(_ item: ShiftTier) -> ShiftTierView {
        return ShiftTierView(
            code: item.code,
            name: item.name,
            durationMinutesText: String(item.durationMinutes),
            externalRefText: item.externalRef,
            archived: "\(item.archived)",
            minimum: String(format: "%.2f", item.minimum),
            phoneText: item.phone,
            refillsText: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftTierViews(_ items: [ShiftTier]) -> [ShiftTierView] {
        var views: [ShiftTierView] = []
        for item in items {
            views.append(toShiftTierView(item))
        }
        return views
    }

    static func sumShiftTierView(_ view: ShiftTierView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedDurationMinutes) + parsedMinimum + Double(parsedRefills)
    }
}
