import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a strict handoff quota.
    final class StrictHandoffQuotaView {
        var code: String
        var name: String
        var notesText: String
        var segment: String
        var cost: String
        var versionText: String
        var statusLabel: String

        init(code: String, name: String, notesText: String, segment: String, cost: String, versionText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.notesText = notesText
            self.segment = segment
            self.cost = cost
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictHandoffQuotaView(_ item: StrictHandoffQuota) -> StrictHandoffQuotaView {
        return StrictHandoffQuotaView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            notesText: item.notes,
            segment: item.segment,
            cost: String(format: "%.2f", item.cost),
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictHandoffQuotaViews(_ items: [StrictHandoffQuota]) -> [StrictHandoffQuotaView] {
        var views: [StrictHandoffQuotaView] = []
        for item in items {
            views.append(toStrictHandoffQuotaView(item))
        }
        return views
    }

    static func sumStrictHandoffQuotaView(_ view: StrictHandoffQuotaView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedCost + Double(parsedVersion)
    }
}
