import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score forecast is in its life cycle.
    enum RiskScoreForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a risk score forecast and its current status.
    final class RiskScoreForecast {
        var code: String
        var label: String
        var threshold: Double
        var ratio: Double
        var margin: Double
        var cost: Double
        var durationMinutes: Int
        var patientRef: String
        var capacity: Int
        var status: RiskScoreForecastStatus

        init(code: String, label: String, threshold: Double, ratio: Double, margin: Double, cost: Double, durationMinutes: Int, patientRef: String, capacity: Int, status: RiskScoreForecastStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.ratio = ratio
            self.margin = margin
            self.cost = cost
            self.durationMinutes = durationMinutes
            self.patientRef = patientRef
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreForecastStatus) -> Bool {
            switch status {
            case .created:
                return next == RiskScoreForecastStatus.retired
            case .validated:
                return next == RiskScoreForecastStatus.retired
            case .published:
                return next == RiskScoreForecastStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return ((Double(durationMinutes) - cost) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreForecast {
            return RiskScoreForecast(
                code: code,
                label: label,
                threshold: threshold,
                ratio: ratio,
                margin: margin,
                cost: cost,
                durationMinutes: durationMinutes,
                patientRef: patientRef,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a risk score forecast in status created.
    static func newRiskScoreForecast(_ code: String, label: String) -> RiskScoreForecast {
        return RiskScoreForecast(
            code: code,
            label: label,
            threshold: 0.0,
            ratio: 0.0,
            margin: 0.0,
            cost: 0.0,
            durationMinutes: 0,
            patientRef: "",
            capacity: 0,
            status: RiskScoreForecastStatus.created
        )
    }
}
