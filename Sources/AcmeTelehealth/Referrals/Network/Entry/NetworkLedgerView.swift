import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network ledger.
    final class NetworkLedgerView {
        var codeText: String
        var title: String
        var budget: String
        var durationMinutesText: String
        var channel: String
        var encounterID: String
        var minimum: String
        var statusLabel: String

        init(codeText: String, title: String, budget: String, durationMinutesText: String, channel: String, encounterID: String, minimum: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.budget = budget
            self.durationMinutesText = durationMinutesText
            self.channel = channel
            self.encounterID = encounterID
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkLedgerView(_ item: NetworkLedger) -> NetworkLedgerView {
        return NetworkLedgerView(
            codeText: item.code,
            title: item.title,
            budget: String(format: "%.2f", item.budget),
            durationMinutesText: String(item.durationMinutes),
            channel: Kit.Text.truncate(item.channel, limit: 120),
            encounterID: item.encounterID,
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkLedgerViews(_ items: [NetworkLedger]) -> [NetworkLedgerView] {
        var views: [NetworkLedgerView] = []
        for item in items {
            views.append(toNetworkLedgerView(item))
        }
        return views
    }

    static func sumNetworkLedgerView(_ view: NetworkLedgerView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedBudget + Double(parsedDurationMinutes) + parsedMinimum
    }
}
