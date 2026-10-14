import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a pending revocation claim.
    final class PendingRevocationClaimView {
        var code: String
        var titleText: String
        var versionText: String
        var limit: String
        var name: String
        var regionText: String
        var facility: String
        var checksum: String
        var payer: String
        var statusLabel: String

        init(code: String, titleText: String, versionText: String, limit: String, name: String, regionText: String, facility: String, checksum: String, payer: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.versionText = versionText
            self.limit = limit
            self.name = name
            self.regionText = regionText
            self.facility = facility
            self.checksum = checksum
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toPendingRevocationClaimView(_ item: PendingRevocationClaim) -> PendingRevocationClaimView {
        return PendingRevocationClaimView(
            code: item.code,
            titleText: item.title,
            versionText: String(item.version),
            limit: String(item.limit),
            name: item.name,
            regionText: item.region,
            facility: item.facility,
            checksum: item.checksum,
            payer: Kit.Text.truncate(item.payer, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingRevocationClaimViews(_ items: [PendingRevocationClaim]) -> [PendingRevocationClaimView] {
        var views: [PendingRevocationClaimView] = []
        for item in items {
            views.append(toPendingRevocationClaimView(item))
        }
        return views
    }

    static func sumPendingRevocationClaimView(_ view: PendingRevocationClaimView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedVersion) + Double(parsedLimit)
    }
}
