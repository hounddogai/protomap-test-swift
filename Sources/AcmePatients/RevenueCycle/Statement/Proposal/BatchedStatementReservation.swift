import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched statement reservation is in its life cycle.
    enum BatchedStatementReservationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One batched statement reservation, with what the planners need to act on it.
    final class BatchedStatementReservation {
        var code: String
        var label: String
        var payer: String
        var visible: Bool
        var copay: Double
        var diagnosisCode: String
        var status: BatchedStatementReservationStatus

        init(code: String, label: String, payer: String, visible: Bool, copay: Double, diagnosisCode: String, status: BatchedStatementReservationStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.visible = visible
            self.copay = copay
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedStatementReservationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == BatchedStatementReservationStatus.running || next == BatchedStatementReservationStatus.done
            case .running:
                return next == BatchedStatementReservationStatus.failed
            case .done:
                return next == BatchedStatementReservationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedStatementReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched statement reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> BatchedStatementReservation {
            return BatchedStatementReservation(
                code: code,
                label: label,
                payer: payer,
                visible: visible,
                copay: copay,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched statement reservation in status new.
    static func newBatchedStatementReservation(_ code: String, label: String) -> BatchedStatementReservation {
        return BatchedStatementReservation(
            code: code,
            label: label,
            payer: "",
            visible: false,
            copay: 0.0,
            diagnosisCode: "",
            status: BatchedStatementReservationStatus.new
        )
    }
}
