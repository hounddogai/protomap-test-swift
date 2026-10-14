import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language ledger.
    final class LanguageLedgerView {
        var code: String
        var name: String
        var updatedAt: String
        var currency: String
        var batchSizeText: String
        var externalRefText: String
        var reviewer: String
        var durationMinutes: String
        var allergy: String
        var localeText: String
        var statusLabel: String

        init(code: String, name: String, updatedAt: String, currency: String, batchSizeText: String, externalRefText: String, reviewer: String, durationMinutes: String, allergy: String, localeText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.currency = currency
            self.batchSizeText = batchSizeText
            self.externalRefText = externalRefText
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.allergy = allergy
            self.localeText = localeText
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageLedgerView(_ item: LanguageLedger) -> LanguageLedgerView {
        return LanguageLedgerView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            updatedAt: String(item.updatedAt),
            currency: item.currency,
            batchSizeText: String(item.batchSize),
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 120),
            reviewer: item.reviewer,
            durationMinutes: String(item.durationMinutes),
            allergy: Kit.Text.truncate(item.allergy, limit: 120),
            localeText: Kit.Text.truncate(item.locale, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageLedgerViews(_ items: [LanguageLedger]) -> [LanguageLedgerView] {
        var views: [LanguageLedgerView] = []
        for item in items {
            views.append(toLanguageLedgerView(item))
        }
        return views
    }

    static func sumLanguageLedgerView(_ view: LanguageLedgerView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedBatchSize) + Double(parsedDurationMinutes)
    }
}
