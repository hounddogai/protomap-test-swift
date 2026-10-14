import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback transfer plan.
    final class FallbackTransferPlanView {
        var codeText: String
        var labelText: String
        var copayText: String
        var quantityText: String
        var checksum: String
        var rate: String
        var patientRef: String
        var statusLabel: String

        init(codeText: String, labelText: String, copayText: String, quantityText: String, checksum: String, rate: String, patientRef: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.copayText = copayText
            self.quantityText = quantityText
            self.checksum = checksum
            self.rate = rate
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackTransferPlanView(_ item: FallbackTransferPlan) -> FallbackTransferPlanView {
        return FallbackTransferPlanView(
            codeText: item.code,
            labelText: item.label,
            copayText: String(format: "%.2f", item.copay),
            quantityText: String(item.quantity),
            checksum: Kit.Text.truncate(item.checksum, limit: 120),
            rate: String(format: "%.2f", item.rate),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackTransferPlanViews(_ items: [FallbackTransferPlan]) -> [FallbackTransferPlanView] {
        var views: [FallbackTransferPlanView] = []
        for item in items {
            views.append(toFallbackTransferPlanView(item))
        }
        return views
    }

    static func sumFallbackTransferPlanView(_ view: FallbackTransferPlanView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedCopay + Double(parsedQuantity) + parsedRate
    }
}
