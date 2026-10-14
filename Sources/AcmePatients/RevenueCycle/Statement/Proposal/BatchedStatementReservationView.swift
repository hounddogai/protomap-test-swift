import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched statement reservation.
    final class BatchedStatementReservationView {
        var code: String
        var label: String
        var payer: String
        var visible: String
        var copay: String
        var diagnosisCodeText: String
        var statusLabel: String

        init(code: String, label: String, payer: String, visible: String, copay: String, diagnosisCodeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.payer = payer
            self.visible = visible
            self.copay = copay
            self.diagnosisCodeText = diagnosisCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedStatementReservationView(_ item: BatchedStatementReservation) -> BatchedStatementReservationView {
        return BatchedStatementReservationView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            payer: item.payer,
            visible: "\(item.visible)",
            copay: String(format: "%.2f", item.copay),
            diagnosisCodeText: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedStatementReservationViews(_ items: [BatchedStatementReservation]) -> [BatchedStatementReservationView] {
        var views: [BatchedStatementReservationView] = []
        for item in items {
            views.append(toBatchedStatementReservationView(item))
        }
        return views
    }

    static func sumBatchedStatementReservationView(_ view: BatchedStatementReservationView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
