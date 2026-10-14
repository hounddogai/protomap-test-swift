import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback census adjustment.
    final class FallbackCensusAdjustmentView {
        var codeText: String
        var name: String
        var checksumText: String
        var acuity: String
        var copayText: String
        var labelText: String
        var amount: String
        var visitMinutes: String
        var priorityText: String
        var patientRefText: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, name: String, checksumText: String, acuity: String, copayText: String, labelText: String, amount: String, visitMinutes: String, priorityText: String, patientRefText: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.checksumText = checksumText
            self.acuity = acuity
            self.copayText = copayText
            self.labelText = labelText
            self.amount = amount
            self.visitMinutes = visitMinutes
            self.priorityText = priorityText
            self.patientRefText = patientRefText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCensusAdjustmentView(_ item: FallbackCensusAdjustment) -> FallbackCensusAdjustmentView {
        return FallbackCensusAdjustmentView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            checksumText: item.checksum,
            acuity: String(item.acuity),
            copayText: String(format: "%.2f", item.copay),
            labelText: Kit.Text.truncate(item.label, limit: 40),
            amount: String(format: "%.2f", item.amount),
            visitMinutes: String(item.visitMinutes),
            priorityText: String(item.priority),
            patientRefText: item.patientRef,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCensusAdjustmentViews(_ items: [FallbackCensusAdjustment]) -> [FallbackCensusAdjustmentView] {
        var views: [FallbackCensusAdjustmentView] = []
        for item in items {
            views.append(toFallbackCensusAdjustmentView(item))
        }
        return views
    }

    static func sumFallbackCensusAdjustmentView(_ view: FallbackCensusAdjustmentView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedAcuity) + parsedCopay + parsedAmount
    }
}
