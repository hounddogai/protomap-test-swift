import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility checkpoint is in its life cycle.
    enum EligibilityCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One eligibility checkpoint, with what the planners need to act on it.
    final class EligibilityCheckpoint {
        var code: String
        var title: String
        var retries: Int
        var pinned: Bool
        var procedureCode: String
        var currency: String
        var description: String
        var channel: String
        var notes: String
        var visible: Bool
        var status: EligibilityCheckpointStatus

        init(code: String, title: String, retries: Int, pinned: Bool, procedureCode: String, currency: String, description: String, channel: String, notes: String, visible: Bool, status: EligibilityCheckpointStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.pinned = pinned
            self.procedureCode = procedureCode
            self.currency = currency
            self.description = description
            self.channel = channel
            self.notes = notes
            self.visible = visible
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

        func canMoveTo(_ next: EligibilityCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == EligibilityCheckpointStatus.completed
            case .completed:
                return next == EligibilityCheckpointStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> EligibilityCheckpoint {
            return EligibilityCheckpoint(
                code: code,
                title: title,
                retries: retries,
                pinned: pinned,
                procedureCode: procedureCode,
                currency: currency,
                description: description,
                channel: channel,
                notes: notes,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a eligibility checkpoint in status planned.
    static func newEligibilityCheckpoint(_ code: String, title: String) -> EligibilityCheckpoint {
        return EligibilityCheckpoint(
            code: code,
            title: title,
            retries: 0,
            pinned: false,
            procedureCode: "",
            currency: "",
            description: "",
            channel: "",
            notes: "",
            visible: false,
            status: EligibilityCheckpointStatus.planned
        )
    }
}
