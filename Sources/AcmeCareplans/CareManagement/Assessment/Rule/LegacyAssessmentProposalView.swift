import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a legacy assessment proposal.
    final class LegacyAssessmentProposalView {
        var codeText: String
        var name: String
        var currency: String
        var discountText: String
        var specialty: String
        var regionText: String
        var pinned: String
        var facilityText: String
        var startsAt: String
        var statusLabel: String

        init(codeText: String, name: String, currency: String, discountText: String, specialty: String, regionText: String, pinned: String, facilityText: String, startsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.currency = currency
            self.discountText = discountText
            self.specialty = specialty
            self.regionText = regionText
            self.pinned = pinned
            self.facilityText = facilityText
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAssessmentProposalView(_ item: LegacyAssessmentProposal) -> LegacyAssessmentProposalView {
        return LegacyAssessmentProposalView(
            codeText: item.code,
            name: item.name,
            currency: Kit.Text.truncate(item.currency, limit: 40),
            discountText: String(format: "%.2f", item.discount),
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            regionText: item.region,
            pinned: "\(item.pinned)",
            facilityText: item.facility,
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAssessmentProposalViews(_ items: [LegacyAssessmentProposal]) -> [LegacyAssessmentProposalView] {
        var views: [LegacyAssessmentProposalView] = []
        for item in items {
            views.append(toLegacyAssessmentProposalView(item))
        }
        return views
    }

    static func sumLegacyAssessmentProposalView(_ view: LegacyAssessmentProposalView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedDiscount + Double(parsedStartsAt)
    }
}
