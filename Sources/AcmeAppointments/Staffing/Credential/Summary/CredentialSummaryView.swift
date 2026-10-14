import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential summary.
    final class CredentialSummaryView {
        var code: String
        var name: String
        var encounterIDText: String
        var allergy: String
        var updatedAt: String
        var retriesText: String
        var checksumText: String
        var channel: String
        var ceiling: String
        var statusLabel: String

        init(code: String, name: String, encounterIDText: String, allergy: String, updatedAt: String, retriesText: String, checksumText: String, channel: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.encounterIDText = encounterIDText
            self.allergy = allergy
            self.updatedAt = updatedAt
            self.retriesText = retriesText
            self.checksumText = checksumText
            self.channel = channel
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialSummaryView(_ item: CredentialSummary) -> CredentialSummaryView {
        return CredentialSummaryView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 64),
            allergy: item.allergy,
            updatedAt: String(item.updatedAt),
            retriesText: String(item.retries),
            checksumText: item.checksum,
            channel: item.channel,
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialSummaryViews(_ items: [CredentialSummary]) -> [CredentialSummaryView] {
        var views: [CredentialSummaryView] = []
        for item in items {
            views.append(toCredentialSummaryView(item))
        }
        return views
    }

    static func sumCredentialSummaryView(_ view: CredentialSummaryView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedRetries) + parsedCeiling
    }
}
