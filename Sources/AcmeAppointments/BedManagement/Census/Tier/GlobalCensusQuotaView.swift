import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a global census quota.
    final class GlobalCensusQuotaView {
        var code: String
        var nameText: String
        var version: String
        var capacityText: String
        var ward: String
        var activeText: String
        var rate: String
        var country: String
        var channel: String
        var notesText: String
        var amount: String
        var statusLabel: String

        init(code: String, nameText: String, version: String, capacityText: String, ward: String, activeText: String, rate: String, country: String, channel: String, notesText: String, amount: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.version = version
            self.capacityText = capacityText
            self.ward = ward
            self.activeText = activeText
            self.rate = rate
            self.country = country
            self.channel = channel
            self.notesText = notesText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCensusQuotaView(_ item: GlobalCensusQuota) -> GlobalCensusQuotaView {
        return GlobalCensusQuotaView(
            code: item.code,
            nameText: item.name,
            version: String(item.version),
            capacityText: String(item.capacity),
            ward: item.ward,
            activeText: "\(item.active)",
            rate: String(format: "%.2f", item.rate),
            country: Kit.Text.truncate(item.country, limit: 64),
            channel: Kit.Text.truncate(item.channel, limit: 40),
            notesText: Kit.Text.truncate(item.notes, limit: 80),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCensusQuotaViews(_ items: [GlobalCensusQuota]) -> [GlobalCensusQuotaView] {
        var views: [GlobalCensusQuotaView] = []
        for item in items {
            views.append(toGlobalCensusQuotaView(item))
        }
        return views
    }

    static func sumGlobalCensusQuotaView(_ view: GlobalCensusQuotaView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedVersion) + Double(parsedCapacity) + parsedRate
    }
}
