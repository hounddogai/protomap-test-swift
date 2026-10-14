import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a capped disclosure ledger.
    final class CappedDisclosureLedgerView {
        var code: String
        var name: String
        var windowDaysText: String
        var budgetText: String
        var updatedAt: String
        var startsAt: String
        var notesText: String
        var region: String
        var statusLabel: String

        init(code: String, name: String, windowDaysText: String, budgetText: String, updatedAt: String, startsAt: String, notesText: String, region: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.windowDaysText = windowDaysText
            self.budgetText = budgetText
            self.updatedAt = updatedAt
            self.startsAt = startsAt
            self.notesText = notesText
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toCappedDisclosureLedgerView(_ item: CappedDisclosureLedger) -> CappedDisclosureLedgerView {
        return CappedDisclosureLedgerView(
            code: item.code,
            name: item.name,
            windowDaysText: String(item.windowDays),
            budgetText: String(format: "%.2f", item.budget),
            updatedAt: String(item.updatedAt),
            startsAt: String(item.startsAt),
            notesText: item.notes,
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedDisclosureLedgerViews(_ items: [CappedDisclosureLedger]) -> [CappedDisclosureLedgerView] {
        var views: [CappedDisclosureLedgerView] = []
        for item in items {
            views.append(toCappedDisclosureLedgerView(item))
        }
        return views
    }

    static func sumCappedDisclosureLedgerView(_ view: CappedDisclosureLedgerView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedWindowDays) + parsedBudget + Double(parsedUpdatedAt)
    }
}
