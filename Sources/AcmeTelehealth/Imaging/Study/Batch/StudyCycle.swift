import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study cycle is in its life cycle.
    enum StudyCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One study cycle, with what the planners need to act on it.
    final class StudyCycle {
        var code: String
        var label: String
        var bed: String
        var attempts: Int
        var amount: Double
        var facility: String
        var channel: String
        var status: StudyCycleStatus

        init(code: String, label: String, bed: String, attempts: Int, amount: Double, facility: String, channel: String, status: StudyCycleStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.attempts = attempts
            self.amount = amount
            self.facility = facility
            self.channel = channel
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

        func canMoveTo(_ next: StudyCycleStatus) -> Bool {
            switch status {
            case .planned:
                return next == StudyCycleStatus.scheduled
            case .scheduled:
                return next == StudyCycleStatus.completed
            case .inProgress:
                return next == StudyCycleStatus.cancelled
            case .completed:
                return next == StudyCycleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("study cycle") \(code)"
        }

        func weightedExposure() -> Double {
            return (Double(attempts) * amount * 100).rounded() / 100
        }

        func copyValue() -> StudyCycle {
            return StudyCycle(
                code: code,
                label: label,
                bed: bed,
                attempts: attempts,
                amount: amount,
                facility: facility,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a study cycle in status planned.
    static func newStudyCycle(_ code: String, label: String) -> StudyCycle {
        return StudyCycle(
            code: code,
            label: label,
            bed: "",
            attempts: 0,
            amount: 0.0,
            facility: "",
            channel: "",
            status: StudyCycleStatus.planned
        )
    }
}
