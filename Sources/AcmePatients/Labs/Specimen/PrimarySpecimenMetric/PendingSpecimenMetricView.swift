import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending specimen metric.
    final class PendingSpecimenMetricView {
        var code: String
        var labelText: String
        var copayText: String
        var sequence: String
        var attempts: String
        var graceDays: String
        var acuity: String
        var statusLabel: String

        init(code: String, labelText: String, copayText: String, sequence: String, attempts: String, graceDays: String, acuity: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.copayText = copayText
            self.sequence = sequence
            self.attempts = attempts
            self.graceDays = graceDays
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toPendingSpecimenMetricView(_ item: PendingSpecimenMetric) -> PendingSpecimenMetricView {
        return PendingSpecimenMetricView(
            code: item.code,
            labelText: item.label,
            copayText: String(format: "%.2f", item.copay),
            sequence: String(item.sequence),
            attempts: String(item.attempts),
            graceDays: String(item.graceDays),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingSpecimenMetricViews(_ items: [PendingSpecimenMetric]) -> [PendingSpecimenMetricView] {
        var views: [PendingSpecimenMetricView] = []
        for item in items {
            views.append(toPendingSpecimenMetricView(item))
        }
        return views
    }

    static func sumPendingSpecimenMetricView(_ view: PendingSpecimenMetricView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedCopay + Double(parsedSequence) + Double(parsedAttempts)
    }
}
