import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality quota.
    final class ModalityQuotaView {
        var code: String
        var title: String
        var payer: String
        var ward: String
        var version: String
        var checksumText: String
        var externalRef: String
        var country: String
        var segmentText: String
        var regionText: String
        var priority: String
        var statusLabel: String

        init(code: String, title: String, payer: String, ward: String, version: String, checksumText: String, externalRef: String, country: String, segmentText: String, regionText: String, priority: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.payer = payer
            self.ward = ward
            self.version = version
            self.checksumText = checksumText
            self.externalRef = externalRef
            self.country = country
            self.segmentText = segmentText
            self.regionText = regionText
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toModalityQuotaView(_ item: ModalityQuota) -> ModalityQuotaView {
        return ModalityQuotaView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            payer: item.payer,
            ward: Kit.Text.truncate(item.ward, limit: 120),
            version: String(item.version),
            checksumText: Kit.Text.truncate(item.checksum, limit: 80),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            country: item.country,
            segmentText: item.segment,
            regionText: item.region,
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityQuotaViews(_ items: [ModalityQuota]) -> [ModalityQuotaView] {
        var views: [ModalityQuotaView] = []
        for item in items {
            views.append(toModalityQuotaView(item))
        }
        return views
    }

    static func sumModalityQuotaView(_ view: ModalityQuotaView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedVersion) + Double(parsedPriority)
    }
}
