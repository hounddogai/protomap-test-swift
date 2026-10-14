import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled bed board proposal.
    final class ScheduledBedBoardProposalView {
        var code: String
        var label: String
        var acuity: String
        var summaryText: String
        var checksumText: String
        var cost: String
        var ownerID: String
        var dosageMg: String
        var floorValueText: String
        var patientRef: String
        var pinned: String
        var statusLabel: String

        init(code: String, label: String, acuity: String, summaryText: String, checksumText: String, cost: String, ownerID: String, dosageMg: String, floorValueText: String, patientRef: String, pinned: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.summaryText = summaryText
            self.checksumText = checksumText
            self.cost = cost
            self.ownerID = ownerID
            self.dosageMg = dosageMg
            self.floorValueText = floorValueText
            self.patientRef = patientRef
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledBedBoardProposalView(_ item: ScheduledBedBoardProposal) -> ScheduledBedBoardProposalView {
        return ScheduledBedBoardProposalView(
            code: item.code,
            label: item.label,
            acuity: String(item.acuity),
            summaryText: item.summary,
            checksumText: item.checksum,
            cost: String(format: "%.2f", item.cost),
            ownerID: item.ownerID,
            dosageMg: String(format: "%.2f", item.dosageMg),
            floorValueText: String(format: "%.2f", item.floorValue),
            patientRef: item.patientRef,
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledBedBoardProposalViews(_ items: [ScheduledBedBoardProposal]) -> [ScheduledBedBoardProposalView] {
        var views: [ScheduledBedBoardProposalView] = []
        for item in items {
            views.append(toScheduledBedBoardProposalView(item))
        }
        return views
    }

    static func sumScheduledBedBoardProposalView(_ view: ScheduledBedBoardProposalView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedAcuity) + parsedCost + parsedDosageMg
    }
}
