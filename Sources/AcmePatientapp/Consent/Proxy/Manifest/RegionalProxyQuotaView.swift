import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional proxy quota.
    final class RegionalProxyQuotaView {
        var code: String
        var nameText: String
        var facilityText: String
        var copayText: String
        var sourceText: String
        var unit: String
        var encounterID: String
        var startsAt: String
        var statusLabel: String

        init(code: String, nameText: String, facilityText: String, copayText: String, sourceText: String, unit: String, encounterID: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.facilityText = facilityText
            self.copayText = copayText
            self.sourceText = sourceText
            self.unit = unit
            self.encounterID = encounterID
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalProxyQuotaView(_ item: RegionalProxyQuota) -> RegionalProxyQuotaView {
        return RegionalProxyQuotaView(
            code: item.code,
            nameText: item.name,
            facilityText: item.facility,
            copayText: String(format: "%.2f", item.copay),
            sourceText: Kit.Text.truncate(item.source, limit: 80),
            unit: Kit.Text.truncate(item.unit, limit: 120),
            encounterID: item.encounterID,
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalProxyQuotaViews(_ items: [RegionalProxyQuota]) -> [RegionalProxyQuotaView] {
        var views: [RegionalProxyQuotaView] = []
        for item in items {
            views.append(toRegionalProxyQuotaView(item))
        }
        return views
    }

    static func sumRegionalProxyQuotaView(_ view: RegionalProxyQuotaView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedCopay + Double(parsedStartsAt)
    }
}
