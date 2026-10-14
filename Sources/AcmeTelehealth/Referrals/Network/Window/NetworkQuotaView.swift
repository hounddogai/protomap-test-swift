import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network quota.
    final class NetworkQuotaView {
        var codeText: String
        var title: String
        var minimum: String
        var notesText: String
        var retries: String
        var encounterID: String
        var limit: String
        var pinned: String
        var source: String
        var statusLabel: String

        init(codeText: String, title: String, minimum: String, notesText: String, retries: String, encounterID: String, limit: String, pinned: String, source: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.minimum = minimum
            self.notesText = notesText
            self.retries = retries
            self.encounterID = encounterID
            self.limit = limit
            self.pinned = pinned
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkQuotaView(_ item: NetworkQuota) -> NetworkQuotaView {
        return NetworkQuotaView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            minimum: String(format: "%.2f", item.minimum),
            notesText: item.notes,
            retries: String(item.retries),
            encounterID: item.encounterID,
            limit: String(item.limit),
            pinned: "\(item.pinned)",
            source: Kit.Text.truncate(item.source, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkQuotaViews(_ items: [NetworkQuota]) -> [NetworkQuotaView] {
        var views: [NetworkQuotaView] = []
        for item in items {
            views.append(toNetworkQuotaView(item))
        }
        return views
    }

    static func sumNetworkQuotaView(_ view: NetworkQuotaView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedMinimum + Double(parsedRetries) + Double(parsedLimit)
    }
}
