import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol quota.
    final class CareProtocolQuotaView {
        var code: String
        var label: String
        var floorValue: String
        var channel: String
        var windowDays: String
        var name: String
        var statusLabel: String

        init(code: String, label: String, floorValue: String, channel: String, windowDays: String, name: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.channel = channel
            self.windowDays = windowDays
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolQuotaView(_ item: CareProtocolQuota) -> CareProtocolQuotaView {
        return CareProtocolQuotaView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            floorValue: String(format: "%.2f", item.floorValue),
            channel: item.channel,
            windowDays: String(item.windowDays),
            name: Kit.Text.truncate(item.name, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolQuotaViews(_ items: [CareProtocolQuota]) -> [CareProtocolQuotaView] {
        var views: [CareProtocolQuotaView] = []
        for item in items {
            views.append(toCareProtocolQuotaView(item))
        }
        return views
    }

    static func sumCareProtocolQuotaView(_ view: CareProtocolQuotaView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedFloorValue + Double(parsedWindowDays)
    }
}
