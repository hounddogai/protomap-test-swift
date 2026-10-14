import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a primary authorization slot.
    final class PrimaryAuthorizationSlotView {
        var code: String
        var title: String
        var durationMinutes: String
        var unit: String
        var countryText: String
        var phone: String
        var limitText: String
        var statusLabel: String

        init(code: String, title: String, durationMinutes: String, unit: String, countryText: String, phone: String, limitText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.unit = unit
            self.countryText = countryText
            self.phone = phone
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryAuthorizationSlotView(_ item: PrimaryAuthorizationSlot) -> PrimaryAuthorizationSlotView {
        return PrimaryAuthorizationSlotView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            durationMinutes: String(item.durationMinutes),
            unit: item.unit,
            countryText: Kit.Text.truncate(item.country, limit: 120),
            phone: item.phone,
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryAuthorizationSlotViews(_ items: [PrimaryAuthorizationSlot]) -> [PrimaryAuthorizationSlotView] {
        var views: [PrimaryAuthorizationSlotView] = []
        for item in items {
            views.append(toPrimaryAuthorizationSlotView(item))
        }
        return views
    }

    static func sumPrimaryAuthorizationSlotView(_ view: PrimaryAuthorizationSlotView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedLimit)
    }
}
