import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a strict slot ledger.
    final class StrictSlotLedgerView {
        var code: String
        var title: String
        var segment: String
        var weightText: String
        var locale: String
        var clinicianID: String
        var expiresAtText: String
        var rate: String
        var timezone: String
        var notes: String
        var statusLabel: String

        init(code: String, title: String, segment: String, weightText: String, locale: String, clinicianID: String, expiresAtText: String, rate: String, timezone: String, notes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.segment = segment
            self.weightText = weightText
            self.locale = locale
            self.clinicianID = clinicianID
            self.expiresAtText = expiresAtText
            self.rate = rate
            self.timezone = timezone
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toStrictSlotLedgerView(_ item: StrictSlotLedger) -> StrictSlotLedgerView {
        return StrictSlotLedgerView(
            code: item.code,
            title: item.title,
            segment: Kit.Text.truncate(item.segment, limit: 120),
            weightText: String(format: "%.2f", item.weight),
            locale: item.locale,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            expiresAtText: String(item.expiresAt),
            rate: String(format: "%.2f", item.rate),
            timezone: item.timezone,
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictSlotLedgerViews(_ items: [StrictSlotLedger]) -> [StrictSlotLedgerView] {
        var views: [StrictSlotLedgerView] = []
        for item in items {
            views.append(toStrictSlotLedgerView(item))
        }
        return views
    }

    static func sumStrictSlotLedgerView(_ view: StrictSlotLedgerView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedWeight + Double(parsedExpiresAt) + parsedRate
    }
}
