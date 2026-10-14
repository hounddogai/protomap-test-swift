import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a tiered network entry.
    final class TieredNetworkEntryView {
        var code: String
        var title: String
        var locale: String
        var attempts: String
        var endsAt: String
        var notes: String
        var checksum: String
        var ownerID: String
        var allergy: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, title: String, locale: String, attempts: String, endsAt: String, notes: String, checksum: String, ownerID: String, allergy: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.locale = locale
            self.attempts = attempts
            self.endsAt = endsAt
            self.notes = notes
            self.checksum = checksum
            self.ownerID = ownerID
            self.allergy = allergy
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toTieredNetworkEntryView(_ item: TieredNetworkEntry) -> TieredNetworkEntryView {
        return TieredNetworkEntryView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            locale: item.locale,
            attempts: String(item.attempts),
            endsAt: String(item.endsAt),
            notes: item.notes,
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            allergy: item.allergy,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredNetworkEntryViews(_ items: [TieredNetworkEntry]) -> [TieredNetworkEntryView] {
        var views: [TieredNetworkEntryView] = []
        for item in items {
            views.append(toTieredNetworkEntryView(item))
        }
        return views
    }

    static func sumTieredNetworkEntryView(_ view: TieredNetworkEntryView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedAttempts) + Double(parsedEndsAt)
    }
}
