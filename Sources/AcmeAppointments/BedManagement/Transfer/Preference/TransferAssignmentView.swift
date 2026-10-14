import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer assignment.
    final class TransferAssignmentView {
        var codeText: String
        var labelText: String
        var payer: String
        var summary: String
        var acuity: String
        var floorValueText: String
        var expiresAt: String
        var encounterIDText: String
        var endsAtText: String
        var titleText: String
        var regionText: String
        var statusLabel: String

        init(codeText: String, labelText: String, payer: String, summary: String, acuity: String, floorValueText: String, expiresAt: String, encounterIDText: String, endsAtText: String, titleText: String, regionText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.payer = payer
            self.summary = summary
            self.acuity = acuity
            self.floorValueText = floorValueText
            self.expiresAt = expiresAt
            self.encounterIDText = encounterIDText
            self.endsAtText = endsAtText
            self.titleText = titleText
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toTransferAssignmentView(_ item: TransferAssignment) -> TransferAssignmentView {
        return TransferAssignmentView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            labelText: Kit.Text.truncate(item.label, limit: 80),
            payer: Kit.Text.truncate(item.payer, limit: 80),
            summary: item.summary,
            acuity: String(item.acuity),
            floorValueText: String(format: "%.2f", item.floorValue),
            expiresAt: String(item.expiresAt),
            encounterIDText: item.encounterID,
            endsAtText: String(item.endsAt),
            titleText: item.title,
            regionText: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferAssignmentViews(_ items: [TransferAssignment]) -> [TransferAssignmentView] {
        var views: [TransferAssignmentView] = []
        for item in items {
            views.append(toTransferAssignmentView(item))
        }
        return views
    }

    static func sumTransferAssignmentView(_ view: TransferAssignmentView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedAcuity) + parsedFloorValue + Double(parsedExpiresAt)
    }
}
