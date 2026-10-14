import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy allocation.
    final class ProxyAllocationView {
        var code: String
        var nameText: String
        var ceiling: String
        var channel: String
        var batchSize: String
        var statusLabel: String

        init(code: String, nameText: String, ceiling: String, channel: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ceiling = ceiling
            self.channel = channel
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toProxyAllocationView(_ item: ProxyAllocation) -> ProxyAllocationView {
        return ProxyAllocationView(
            code: item.code,
            nameText: item.name,
            ceiling: String(format: "%.2f", item.ceiling),
            channel: item.channel,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyAllocationViews(_ items: [ProxyAllocation]) -> [ProxyAllocationView] {
        var views: [ProxyAllocationView] = []
        for item in items {
            views.append(toProxyAllocationView(item))
        }
        return views
    }

    static func sumProxyAllocationView(_ view: ProxyAllocationView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedCeiling + Double(parsedBatchSize)
    }
}
