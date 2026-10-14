import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation target is in its life cycle.
    enum IsolationTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One isolation target, with what the planners need to act on it.
    final class IsolationTarget {
        var code: String
        var label: String
        var ownerID: String
        var notes: String
        var channel: String
        var sequence: Int
        var status: IsolationTargetStatus

        init(code: String, label: String, ownerID: String, notes: String, channel: String, sequence: Int, status: IsolationTargetStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.notes = notes
            self.channel = channel
            self.sequence = sequence
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

        func canMoveTo(_ next: IsolationTargetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: IsolationTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(sequence)
        }

        func copyValue() -> IsolationTarget {
            return IsolationTarget(
                code: code,
                label: label,
                ownerID: ownerID,
                notes: notes,
                channel: channel,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a isolation target in status proposed.
    static func newIsolationTarget(_ code: String, label: String) -> IsolationTarget {
        return IsolationTarget(
            code: code,
            label: label,
            ownerID: "",
            notes: "",
            channel: "",
            sequence: 0,
            status: IsolationTargetStatus.proposed
        )
    }
}
