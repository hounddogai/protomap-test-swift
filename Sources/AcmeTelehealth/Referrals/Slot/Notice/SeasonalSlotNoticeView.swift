import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal slot notice.
    final class SeasonalSlotNoticeView {
        var codeText: String
        var label: String
        var startsAtText: String
        var sequence: String
        var attempts: String
        var currency: String
        var quantity: String
        var encounterID: String
        var archivedText: String
        var version: String
        var statusLabel: String

        init(codeText: String, label: String, startsAtText: String, sequence: String, attempts: String, currency: String, quantity: String, encounterID: String, archivedText: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.startsAtText = startsAtText
            self.sequence = sequence
            self.attempts = attempts
            self.currency = currency
            self.quantity = quantity
            self.encounterID = encounterID
            self.archivedText = archivedText
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalSlotNoticeView(_ item: SeasonalSlotNotice) -> SeasonalSlotNoticeView {
        return SeasonalSlotNoticeView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            startsAtText: String(item.startsAt),
            sequence: String(item.sequence),
            attempts: String(item.attempts),
            currency: item.currency,
            quantity: String(item.quantity),
            encounterID: item.encounterID,
            archivedText: "\(item.archived)",
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalSlotNoticeViews(_ items: [SeasonalSlotNotice]) -> [SeasonalSlotNoticeView] {
        var views: [SeasonalSlotNoticeView] = []
        for item in items {
            views.append(toSeasonalSlotNoticeView(item))
        }
        return views
    }

    static func sumSeasonalSlotNoticeView(_ view: SeasonalSlotNoticeView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedSequence) + Double(parsedAttempts)
    }
}
