import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a tiered care protocol claim.
    final class TieredCareProtocolClaimView {
        var codeText: String
        var labelText: String
        var procedureCode: String
        var specialty: String
        var categoryText: String
        var reviewer: String
        var revision: String
        var acuity: String
        var facility: String
        var pinned: String
        var statusLabel: String

        init(codeText: String, labelText: String, procedureCode: String, specialty: String, categoryText: String, reviewer: String, revision: String, acuity: String, facility: String, pinned: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.procedureCode = procedureCode
            self.specialty = specialty
            self.categoryText = categoryText
            self.reviewer = reviewer
            self.revision = revision
            self.acuity = acuity
            self.facility = facility
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toTieredCareProtocolClaimView(_ item: TieredCareProtocolClaim) -> TieredCareProtocolClaimView {
        return TieredCareProtocolClaimView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            procedureCode: item.procedureCode,
            specialty: Kit.Text.truncate(item.specialty, limit: 64),
            categoryText: Kit.Text.truncate(item.category, limit: 120),
            reviewer: item.reviewer,
            revision: String(item.revision),
            acuity: String(item.acuity),
            facility: item.facility,
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredCareProtocolClaimViews(_ items: [TieredCareProtocolClaim]) -> [TieredCareProtocolClaimView] {
        var views: [TieredCareProtocolClaimView] = []
        for item in items {
            views.append(toTieredCareProtocolClaimView(item))
        }
        return views
    }

    static func sumTieredCareProtocolClaimView(_ view: TieredCareProtocolClaimView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedRevision) + Double(parsedAcuity)
    }
}
