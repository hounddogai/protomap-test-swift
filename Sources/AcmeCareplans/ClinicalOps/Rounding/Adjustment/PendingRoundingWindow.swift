import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending rounding window is in its life cycle.
    enum PendingRoundingWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a pending rounding window and its current status.
    final class PendingRoundingWindow {
        var code: String
        var label: String
        var quantity: Int
        var timezone: String
        var patientRef: String
        var active: Bool
        var sequence: Int
        var status: PendingRoundingWindowStatus

        init(code: String, label: String, quantity: Int, timezone: String, patientRef: String, active: Bool, sequence: Int, status: PendingRoundingWindowStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.timezone = timezone
            self.patientRef = patientRef
            self.active = active
            self.sequence = sequence
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

        func canMoveTo(_ next: PendingRoundingWindowStatus) -> Bool {
            switch status {
            case .new:
                return next == PendingRoundingWindowStatus.done || next == PendingRoundingWindowStatus.failed
            case .queued:
                return next == PendingRoundingWindowStatus.done || next == PendingRoundingWindowStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == PendingRoundingWindowStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingRoundingWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending rounding window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedLoad() -> Double {
            return ((Double(sequence) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> PendingRoundingWindow {
            return PendingRoundingWindow(
                code: code,
                label: label,
                quantity: quantity,
                timezone: timezone,
                patientRef: patientRef,
                active: active,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending rounding window in status new.
    static func newPendingRoundingWindow(_ code: String, label: String) -> PendingRoundingWindow {
        return PendingRoundingWindow(
            code: code,
            label: label,
            quantity: 0,
            timezone: "",
            patientRef: "",
            active: false,
            sequence: 0,
            status: PendingRoundingWindowStatus.new
        )
    }
}
