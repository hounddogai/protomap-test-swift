import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy transfer window.
    final class LegacyTransferWindowView {
        var codeText: String
        var name: String
        var expiresAt: String
        var locale: String
        var rateText: String
        var notesText: String
        var pinned: String
        var sequenceText: String
        var updatedAtText: String
        var createdAt: String
        var statusLabel: String

        init(codeText: String, name: String, expiresAt: String, locale: String, rateText: String, notesText: String, pinned: String, sequenceText: String, updatedAtText: String, createdAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.expiresAt = expiresAt
            self.locale = locale
            self.rateText = rateText
            self.notesText = notesText
            self.pinned = pinned
            self.sequenceText = sequenceText
            self.updatedAtText = updatedAtText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyTransferWindowView(_ item: LegacyTransferWindow) -> LegacyTransferWindowView {
        return LegacyTransferWindowView(
            codeText: item.code,
            name: item.name,
            expiresAt: String(item.expiresAt),
            locale: Kit.Text.truncate(item.locale, limit: 64),
            rateText: String(format: "%.2f", item.rate),
            notesText: item.notes,
            pinned: "\(item.pinned)",
            sequenceText: String(item.sequence),
            updatedAtText: String(item.updatedAt),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyTransferWindowViews(_ items: [LegacyTransferWindow]) -> [LegacyTransferWindowView] {
        var views: [LegacyTransferWindowView] = []
        for item in items {
            views.append(toLegacyTransferWindowView(item))
        }
        return views
    }

    static func sumLegacyTransferWindowView(_ view: LegacyTransferWindowView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedExpiresAt) + parsedRate + Double(parsedSequence)
    }
}
