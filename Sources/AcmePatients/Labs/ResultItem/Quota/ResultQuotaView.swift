import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result quota.
    final class ResultQuotaView {
        var code: String
        var label: String
        var endsAtText: String
        var cost: String
        var version: String
        var channelText: String
        var segmentText: String
        var statusLabel: String

        init(code: String, label: String, endsAtText: String, cost: String, version: String, channelText: String, segmentText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.endsAtText = endsAtText
            self.cost = cost
            self.version = version
            self.channelText = channelText
            self.segmentText = segmentText
            self.statusLabel = statusLabel
        }
    }

    static func toResultQuotaView(_ item: ResultQuota) -> ResultQuotaView {
        return ResultQuotaView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 120),
            endsAtText: String(item.endsAt),
            cost: String(format: "%.2f", item.cost),
            version: String(item.version),
            channelText: item.channel,
            segmentText: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultQuotaViews(_ items: [ResultQuota]) -> [ResultQuotaView] {
        var views: [ResultQuotaView] = []
        for item in items {
            views.append(toResultQuotaView(item))
        }
        return views
    }

    static func sumResultQuotaView(_ view: ResultQuotaView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedEndsAt) + parsedCost + Double(parsedVersion)
    }
}
