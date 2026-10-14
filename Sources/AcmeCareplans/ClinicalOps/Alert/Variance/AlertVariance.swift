import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert variance is in its life cycle.
    enum AlertVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One alert variance, with what the planners need to act on it.
    final class AlertVariance {
        var code: String
        var label: String
        var visitMinutes: Int
        var threshold: Double
        var description: String
        var encounterID: String
        var name: String
        var status: AlertVarianceStatus

        init(code: String, label: String, visitMinutes: Int, threshold: Double, description: String, encounterID: String, name: String, status: AlertVarianceStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.threshold = threshold
            self.description = description
            self.encounterID = encounterID
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AlertVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AlertVarianceStatus.rejected
            case .approved:
                return next == AlertVarianceStatus.rejected || next == AlertVarianceStatus.withdrawn
            case .rejected:
                return next == AlertVarianceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netLoad() -> Double {
            return ((Double(visitMinutes) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> AlertVariance {
            return AlertVariance(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                threshold: threshold,
                description: description,
                encounterID: encounterID,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a alert variance in status proposed.
    static func newAlertVariance(_ code: String, label: String) -> AlertVariance {
        return AlertVariance(
            code: code,
            label: label,
            visitMinutes: 0,
            threshold: 0.0,
            description: "",
            encounterID: "",
            name: "",
            status: AlertVarianceStatus.proposed
        )
    }
}
