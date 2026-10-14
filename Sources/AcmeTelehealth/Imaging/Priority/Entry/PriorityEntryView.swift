import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority entry.
    final class PriorityEntryView {
        var code: String
        var name: String
        var createdAtText: String
        var durationMinutes: String
        var country: String
        var acuity: String
        var payerText: String
        var windowDays: String
        var ownerIDText: String
        var categoryText: String
        var statusLabel: String

        init(code: String, name: String, createdAtText: String, durationMinutes: String, country: String, acuity: String, payerText: String, windowDays: String, ownerIDText: String, categoryText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.createdAtText = createdAtText
            self.durationMinutes = durationMinutes
            self.country = country
            self.acuity = acuity
            self.payerText = payerText
            self.windowDays = windowDays
            self.ownerIDText = ownerIDText
            self.categoryText = categoryText
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityEntryView(_ item: PriorityEntry) -> PriorityEntryView {
        return PriorityEntryView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            createdAtText: String(item.createdAt),
            durationMinutes: String(item.durationMinutes),
            country: item.country,
            acuity: String(item.acuity),
            payerText: item.payer,
            windowDays: String(item.windowDays),
            ownerIDText: item.ownerID,
            categoryText: Kit.Text.truncate(item.category, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityEntryViews(_ items: [PriorityEntry]) -> [PriorityEntryView] {
        var views: [PriorityEntryView] = []
        for item in items {
            views.append(toPriorityEntryView(item))
        }
        return views
    }

    static func sumPriorityEntryView(_ view: PriorityEntryView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedDurationMinutes) + Double(parsedAcuity)
    }
}
