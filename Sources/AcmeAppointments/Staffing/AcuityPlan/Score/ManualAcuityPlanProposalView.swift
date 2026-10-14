import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a manual acuity plan proposal.
    final class ManualAcuityPlanProposalView {
        var codeText: String
        var name: String
        var batchSize: String
        var locale: String
        var acuity: String
        var countryText: String
        var discount: String
        var checksum: String
        var externalRef: String
        var startsAt: String
        var priority: String
        var statusLabel: String

        init(codeText: String, name: String, batchSize: String, locale: String, acuity: String, countryText: String, discount: String, checksum: String, externalRef: String, startsAt: String, priority: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.batchSize = batchSize
            self.locale = locale
            self.acuity = acuity
            self.countryText = countryText
            self.discount = discount
            self.checksum = checksum
            self.externalRef = externalRef
            self.startsAt = startsAt
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toManualAcuityPlanProposalView(_ item: ManualAcuityPlanProposal) -> ManualAcuityPlanProposalView {
        return ManualAcuityPlanProposalView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            batchSize: String(item.batchSize),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            acuity: String(item.acuity),
            countryText: Kit.Text.truncate(item.country, limit: 80),
            discount: String(format: "%.2f", item.discount),
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            externalRef: item.externalRef,
            startsAt: String(item.startsAt),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualAcuityPlanProposalViews(_ items: [ManualAcuityPlanProposal]) -> [ManualAcuityPlanProposalView] {
        var views: [ManualAcuityPlanProposalView] = []
        for item in items {
            views.append(toManualAcuityPlanProposalView(item))
        }
        return views
    }

    static func sumManualAcuityPlanProposalView(_ view: ManualAcuityPlanProposalView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedAcuity) + parsedDiscount
    }
}
