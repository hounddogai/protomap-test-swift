import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach digest.
    final class OutreachDigestView {
        var code: String
        var name: String
        var expiresAt: String
        var checksum: String
        var allergy: String
        var batchSize: String
        var active: String
        var payer: String
        var statusLabel: String

        init(code: String, name: String, expiresAt: String, checksum: String, allergy: String, batchSize: String, active: String, payer: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.checksum = checksum
            self.allergy = allergy
            self.batchSize = batchSize
            self.active = active
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachDigestView(_ item: OutreachDigest) -> OutreachDigestView {
        return OutreachDigestView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            expiresAt: String(item.expiresAt),
            checksum: item.checksum,
            allergy: item.allergy,
            batchSize: String(item.batchSize),
            active: "\(item.active)",
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachDigestViews(_ items: [OutreachDigest]) -> [OutreachDigestView] {
        var views: [OutreachDigestView] = []
        for item in items {
            views.append(toOutreachDigestView(item))
        }
        return views
    }

    static func sumOutreachDigestView(_ view: OutreachDigestView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedBatchSize)
    }
}
