import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation checkpoint is in its life cycle.
    enum IsolationCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A isolation checkpoint as the isolation team keeps it.
    final class IsolationCheckpoint {
        var code: String
        var label: String
        var ratio: Double
        var archived: Bool
        var weight: Double
        var status: IsolationCheckpointStatus

        init(code: String, label: String, ratio: Double, archived: Bool, weight: Double, status: IsolationCheckpointStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.archived = archived
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationCheckpointStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == IsolationCheckpointStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("isolation checkpoint") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((weight + ratio) * 100).rounded() / 100
        }

        func copyValue() -> IsolationCheckpoint {
            return IsolationCheckpoint(
                code: code,
                label: label,
                ratio: ratio,
                archived: archived,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a isolation checkpoint in status open.
    static func newIsolationCheckpoint(_ code: String, label: String) -> IsolationCheckpoint {
        return IsolationCheckpoint(
            code: code,
            label: label,
            ratio: 0.0,
            archived: false,
            weight: 0.0,
            status: IsolationCheckpointStatus.`open`
        )
    }
}
