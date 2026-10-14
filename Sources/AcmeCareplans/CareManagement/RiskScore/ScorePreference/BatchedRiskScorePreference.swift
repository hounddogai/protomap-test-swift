import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched risk score preference is in its life cycle.
    enum BatchedRiskScorePreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a batched risk score preference and its current status.
    final class BatchedRiskScorePreference {
        var code: String
        var name: String
        var active: Bool
        var patientRef: String
        var payer: String
        var amount: Double
        var status: BatchedRiskScorePreferenceStatus

        init(code: String, name: String, active: Bool, patientRef: String, payer: String, amount: Double, status: BatchedRiskScorePreferenceStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.patientRef = patientRef
            self.payer = payer
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedRiskScorePreferenceStatus) -> Bool {
            switch status {
            case .planned:
                return next == BatchedRiskScorePreferenceStatus.scheduled || next == BatchedRiskScorePreferenceStatus.cancelled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == BatchedRiskScorePreferenceStatus.completed || next == BatchedRiskScorePreferenceStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedRiskScorePreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched risk score preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched risk score preference") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> BatchedRiskScorePreference {
            return BatchedRiskScorePreference(
                code: code,
                name: name,
                active: active,
                patientRef: patientRef,
                payer: payer,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched risk score preference in status planned.
    static func newBatchedRiskScorePreference(_ code: String, name: String) -> BatchedRiskScorePreference {
        return BatchedRiskScorePreference(
            code: code,
            name: name,
            active: false,
            patientRef: "",
            payer: "",
            amount: 0.0,
            status: BatchedRiskScorePreferenceStatus.planned
        )
    }
}
