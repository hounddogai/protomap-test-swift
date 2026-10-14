import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched witness adjustment is in its life cycle.
    enum BatchedWitnessAdjustmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a batched witness adjustment and its current status.
    final class BatchedWitnessAdjustment {
        var code: String
        var label: String
        var graceDays: Int
        var unit: String
        var maximum: Double
        var status: BatchedWitnessAdjustmentStatus

        init(code: String, label: String, graceDays: Int, unit: String, maximum: Double, status: BatchedWitnessAdjustmentStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.unit = unit
            self.maximum = maximum
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

        func canMoveTo(_ next: BatchedWitnessAdjustmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == BatchedWitnessAdjustmentStatus.running || next == BatchedWitnessAdjustmentStatus.done
            case .running:
                return next == BatchedWitnessAdjustmentStatus.done || next == BatchedWitnessAdjustmentStatus.failed
            case .done:
                return next == BatchedWitnessAdjustmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedWitnessAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched witness adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("batched witness adjustment") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((maximum - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedWitnessAdjustment {
            return BatchedWitnessAdjustment(
                code: code,
                label: label,
                graceDays: graceDays,
                unit: unit,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a batched witness adjustment in status new.
    static func newBatchedWitnessAdjustment(_ code: String, label: String) -> BatchedWitnessAdjustment {
        return BatchedWitnessAdjustment(
            code: code,
            label: label,
            graceDays: 0,
            unit: "",
            maximum: 0.0,
            status: BatchedWitnessAdjustmentStatus.new
        )
    }
}
