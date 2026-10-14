import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a lenient language ledger.
    final class LenientLanguageLedgerView {
        var codeText: String
        var title: String
        var archived: String
        var channel: String
        var active: String
        var updatedAt: String
        var capacityText: String
        var statusLabel: String

        init(codeText: String, title: String, archived: String, channel: String, active: String, updatedAt: String, capacityText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.archived = archived
            self.channel = channel
            self.active = active
            self.updatedAt = updatedAt
            self.capacityText = capacityText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientLanguageLedgerView(_ item: LenientLanguageLedger) -> LenientLanguageLedgerView {
        return LenientLanguageLedgerView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 64),
            archived: "\(item.archived)",
            channel: item.channel,
            active: "\(item.active)",
            updatedAt: String(item.updatedAt),
            capacityText: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientLanguageLedgerViews(_ items: [LenientLanguageLedger]) -> [LenientLanguageLedgerView] {
        var views: [LenientLanguageLedgerView] = []
        for item in items {
            views.append(toLenientLanguageLedgerView(item))
        }
        return views
    }

    static func sumLenientLanguageLedgerView(_ view: LenientLanguageLedgerView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedCapacity)
    }
}
