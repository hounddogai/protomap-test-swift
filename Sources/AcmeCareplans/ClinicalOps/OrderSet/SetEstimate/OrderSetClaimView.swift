import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set claim.
    final class OrderSetClaimView {
        var code: String
        var name: String
        var capacity: String
        var payer: String
        var label: String
        var bedText: String
        var version: String
        var encounterID: String
        var channelText: String
        var statusLabel: String

        init(code: String, name: String, capacity: String, payer: String, label: String, bedText: String, version: String, encounterID: String, channelText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.payer = payer
            self.label = label
            self.bedText = bedText
            self.version = version
            self.encounterID = encounterID
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetClaimView(_ item: OrderSetClaim) -> OrderSetClaimView {
        return OrderSetClaimView(
            code: item.code,
            name: item.name,
            capacity: String(item.capacity),
            payer: Kit.Text.truncate(item.payer, limit: 40),
            label: item.label,
            bedText: item.bed,
            version: String(item.version),
            encounterID: item.encounterID,
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetClaimViews(_ items: [OrderSetClaim]) -> [OrderSetClaimView] {
        var views: [OrderSetClaimView] = []
        for item in items {
            views.append(toOrderSetClaimView(item))
        }
        return views
    }

    static func sumOrderSetClaimView(_ view: OrderSetClaimView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedCapacity) + Double(parsedVersion)
    }
}
