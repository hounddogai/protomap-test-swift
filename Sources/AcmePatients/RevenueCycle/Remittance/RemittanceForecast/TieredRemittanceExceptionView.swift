import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered remittance exception.
    final class TieredRemittanceExceptionView {
        var code: String
        var title: String
        var quantity: String
        var specialtyText: String
        var summary: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, title: String, quantity: String, specialtyText: String, summary: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.specialtyText = specialtyText
            self.summary = summary
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRemittanceExceptionView(_ item: TieredRemittanceException) -> TieredRemittanceExceptionView {
        return TieredRemittanceExceptionView(
            code: item.code,
            title: item.title,
            quantity: String(item.quantity),
            specialtyText: Kit.Text.truncate(item.specialty, limit: 64),
            summary: Kit.Text.truncate(item.summary, limit: 120),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRemittanceExceptionViews(_ items: [TieredRemittanceException]) -> [TieredRemittanceExceptionView] {
        var views: [TieredRemittanceExceptionView] = []
        for item in items {
            views.append(toTieredRemittanceExceptionView(item))
        }
        return views
    }

    static func sumTieredRemittanceExceptionView(_ view: TieredRemittanceExceptionView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedQuantity) + Double(parsedDurationMinutes)
    }
}
