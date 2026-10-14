import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual substitution digest.
    final class ManualSubstitutionDigestView {
        var codeText: String
        var nameText: String
        var visibleText: String
        var encounterID: String
        var notes: String
        var locale: String
        var copay: String
        var amount: String
        var statusLabel: String

        init(codeText: String, nameText: String, visibleText: String, encounterID: String, notes: String, locale: String, copay: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.visibleText = visibleText
            self.encounterID = encounterID
            self.notes = notes
            self.locale = locale
            self.copay = copay
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toManualSubstitutionDigestView(_ item: ManualSubstitutionDigest) -> ManualSubstitutionDigestView {
        return ManualSubstitutionDigestView(
            codeText: item.code,
            nameText: item.name,
            visibleText: "\(item.visible)",
            encounterID: item.encounterID,
            notes: Kit.Text.truncate(item.notes, limit: 64),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            copay: String(format: "%.2f", item.copay),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualSubstitutionDigestViews(_ items: [ManualSubstitutionDigest]) -> [ManualSubstitutionDigestView] {
        var views: [ManualSubstitutionDigestView] = []
        for item in items {
            views.append(toManualSubstitutionDigestView(item))
        }
        return views
    }

    static func sumManualSubstitutionDigestView(_ view: ManualSubstitutionDigestView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedCopay + parsedAmount
    }
}
