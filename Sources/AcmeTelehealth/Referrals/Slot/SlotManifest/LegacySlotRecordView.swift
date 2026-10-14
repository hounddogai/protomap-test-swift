import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a legacy slot record.
    final class LegacySlotRecordView {
        var code: String
        var titleText: String
        var expiresAtText: String
        var attempts: String
        var externalRefText: String
        var rate: String
        var minimum: String
        var statusLabel: String

        init(code: String, titleText: String, expiresAtText: String, attempts: String, externalRefText: String, rate: String, minimum: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.expiresAtText = expiresAtText
            self.attempts = attempts
            self.externalRefText = externalRefText
            self.rate = rate
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toLegacySlotRecordView(_ item: LegacySlotRecord) -> LegacySlotRecordView {
        return LegacySlotRecordView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            expiresAtText: String(item.expiresAt),
            attempts: String(item.attempts),
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 80),
            rate: String(format: "%.2f", item.rate),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacySlotRecordViews(_ items: [LegacySlotRecord]) -> [LegacySlotRecordView] {
        var views: [LegacySlotRecordView] = []
        for item in items {
            views.append(toLegacySlotRecordView(item))
        }
        return views
    }

    static func sumLegacySlotRecordView(_ view: LegacySlotRecordView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedAttempts) + parsedRate
    }
}
