import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a lenient slot digest.
    final class LenientSlotDigestView {
        var codeText: String
        var title: String
        var summaryText: String
        var graceDaysText: String
        var batchSize: String
        var durationMinutes: String
        var locale: String
        var labelText: String
        var attempts: String
        var amount: String
        var windowDays: String
        var statusLabel: String

        init(codeText: String, title: String, summaryText: String, graceDaysText: String, batchSize: String, durationMinutes: String, locale: String, labelText: String, attempts: String, amount: String, windowDays: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.summaryText = summaryText
            self.graceDaysText = graceDaysText
            self.batchSize = batchSize
            self.durationMinutes = durationMinutes
            self.locale = locale
            self.labelText = labelText
            self.attempts = attempts
            self.amount = amount
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toLenientSlotDigestView(_ item: LenientSlotDigest) -> LenientSlotDigestView {
        return LenientSlotDigestView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            summaryText: Kit.Text.truncate(item.summary, limit: 40),
            graceDaysText: String(item.graceDays),
            batchSize: String(item.batchSize),
            durationMinutes: String(item.durationMinutes),
            locale: item.locale,
            labelText: item.label,
            attempts: String(item.attempts),
            amount: String(format: "%.2f", item.amount),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientSlotDigestViews(_ items: [LenientSlotDigest]) -> [LenientSlotDigestView] {
        var views: [LenientSlotDigestView] = []
        for item in items {
            views.append(toLenientSlotDigestView(item))
        }
        return views
    }

    static func sumLenientSlotDigestView(_ view: LenientSlotDigestView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedBatchSize) + Double(parsedDurationMinutes)
    }
}
