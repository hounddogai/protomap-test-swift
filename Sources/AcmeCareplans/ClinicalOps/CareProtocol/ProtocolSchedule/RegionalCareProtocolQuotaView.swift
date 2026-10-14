import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a regional care protocol quota.
    final class RegionalCareProtocolQuotaView {
        var code: String
        var name: String
        var descriptionText: String
        var revision: String
        var visitMinutesText: String
        var channel: String
        var phoneText: String
        var reviewer: String
        var statusLabel: String

        init(code: String, name: String, descriptionText: String, revision: String, visitMinutesText: String, channel: String, phoneText: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.descriptionText = descriptionText
            self.revision = revision
            self.visitMinutesText = visitMinutesText
            self.channel = channel
            self.phoneText = phoneText
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalCareProtocolQuotaView(_ item: RegionalCareProtocolQuota) -> RegionalCareProtocolQuotaView {
        return RegionalCareProtocolQuotaView(
            code: item.code,
            name: item.name,
            descriptionText: Kit.Text.truncate(item.description, limit: 120),
            revision: String(item.revision),
            visitMinutesText: String(item.visitMinutes),
            channel: Kit.Text.truncate(item.channel, limit: 40),
            phoneText: item.phone,
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalCareProtocolQuotaViews(_ items: [RegionalCareProtocolQuota]) -> [RegionalCareProtocolQuotaView] {
        var views: [RegionalCareProtocolQuotaView] = []
        for item in items {
            views.append(toRegionalCareProtocolQuotaView(item))
        }
        return views
    }

    static func sumRegionalCareProtocolQuotaView(_ view: RegionalCareProtocolQuotaView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedRevision) + Double(parsedVisitMinutes)
    }
}
