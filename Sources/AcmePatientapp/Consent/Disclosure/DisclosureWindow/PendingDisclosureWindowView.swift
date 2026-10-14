import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a pending disclosure window.
    final class PendingDisclosureWindowView {
        var code: String
        var nameText: String
        var endsAt: String
        var durationMinutes: String
        var margin: String
        var graceDays: String
        var statusLabel: String

        init(code: String, nameText: String, endsAt: String, durationMinutes: String, margin: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.endsAt = endsAt
            self.durationMinutes = durationMinutes
            self.margin = margin
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toPendingDisclosureWindowView(_ item: PendingDisclosureWindow) -> PendingDisclosureWindowView {
        return PendingDisclosureWindowView(
            code: item.code,
            nameText: item.name,
            endsAt: String(item.endsAt),
            durationMinutes: String(item.durationMinutes),
            margin: String(format: "%.2f", item.margin),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingDisclosureWindowViews(_ items: [PendingDisclosureWindow]) -> [PendingDisclosureWindowView] {
        var views: [PendingDisclosureWindowView] = []
        for item in items {
            views.append(toPendingDisclosureWindowView(item))
        }
        return views
    }

    static func sumPendingDisclosureWindowView(_ view: PendingDisclosureWindowView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedDurationMinutes) + parsedMargin
    }
}
