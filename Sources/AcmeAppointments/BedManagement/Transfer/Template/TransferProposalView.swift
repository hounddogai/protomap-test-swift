import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer proposal.
    final class TransferProposalView {
        var code: String
        var label: String
        var ratio: String
        var source: String
        var specialty: String
        var ward: String
        var floorValue: String
        var acuity: String
        var budget: String
        var checksumText: String
        var statusLabel: String

        init(code: String, label: String, ratio: String, source: String, specialty: String, ward: String, floorValue: String, acuity: String, budget: String, checksumText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.source = source
            self.specialty = specialty
            self.ward = ward
            self.floorValue = floorValue
            self.acuity = acuity
            self.budget = budget
            self.checksumText = checksumText
            self.statusLabel = statusLabel
        }
    }

    static func toTransferProposalView(_ item: TransferProposal) -> TransferProposalView {
        return TransferProposalView(
            code: item.code,
            label: item.label,
            ratio: String(format: "%.2f", item.ratio),
            source: Kit.Text.truncate(item.source, limit: 40),
            specialty: item.specialty,
            ward: Kit.Text.truncate(item.ward, limit: 80),
            floorValue: String(format: "%.2f", item.floorValue),
            acuity: String(item.acuity),
            budget: String(format: "%.2f", item.budget),
            checksumText: Kit.Text.truncate(item.checksum, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferProposalViews(_ items: [TransferProposal]) -> [TransferProposalView] {
        var views: [TransferProposalView] = []
        for item in items {
            views.append(toTransferProposalView(item))
        }
        return views
    }

    static func sumTransferProposalView(_ view: TransferProposalView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedRatio + parsedFloorValue + Double(parsedAcuity)
    }
}
