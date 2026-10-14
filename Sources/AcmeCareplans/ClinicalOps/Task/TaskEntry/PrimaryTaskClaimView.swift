import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary task claim.
    final class PrimaryTaskClaimView {
        var code: String
        var labelText: String
        var timezone: String
        var checksumText: String
        var refills: String
        var statusLabel: String

        init(code: String, labelText: String, timezone: String, checksumText: String, refills: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.timezone = timezone
            self.checksumText = checksumText
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryTaskClaimView(_ item: PrimaryTaskClaim) -> PrimaryTaskClaimView {
        return PrimaryTaskClaimView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            timezone: item.timezone,
            checksumText: item.checksum,
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryTaskClaimViews(_ items: [PrimaryTaskClaim]) -> [PrimaryTaskClaimView] {
        var views: [PrimaryTaskClaimView] = []
        for item in items {
            views.append(toPrimaryTaskClaimView(item))
        }
        return views
    }

    static func sumPrimaryTaskClaimView(_ view: PrimaryTaskClaimView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedRefills)
    }
}
