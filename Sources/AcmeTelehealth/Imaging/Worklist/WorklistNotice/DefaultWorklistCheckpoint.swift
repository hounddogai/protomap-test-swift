import AcmePlatform
import Foundation

extension Imaging {
    /// Where a default worklist checkpoint is in its life cycle.
    enum DefaultWorklistCheckpointStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A default worklist checkpoint as the worklist team keeps it.
    final class DefaultWorklistCheckpoint {
        var code: String
        var title: String
        var threshold: Double
        var dosageMg: Double
        var allergy: String
        var capacity: Int
        var status: DefaultWorklistCheckpointStatus

        init(code: String, title: String, threshold: Double, dosageMg: Double, allergy: String, capacity: Int, status: DefaultWorklistCheckpointStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.dosageMg = dosageMg
            self.allergy = allergy
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultWorklistCheckpointStatus) -> Bool {
            switch status {
            case .draft:
                return next == DefaultWorklistCheckpointStatus.pending || next == DefaultWorklistCheckpointStatus.suspended
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == DefaultWorklistCheckpointStatus.closed
            case .suspended:
                return next == DefaultWorklistCheckpointStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultWorklistCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default worklist checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveVolume() -> Double {
            return ((dosageMg + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultWorklistCheckpoint {
            return DefaultWorklistCheckpoint(
                code: code,
                title: title,
                threshold: threshold,
                dosageMg: dosageMg,
                allergy: allergy,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default worklist checkpoint in status draft.
    static func newDefaultWorklistCheckpoint(_ code: String, title: String) -> DefaultWorklistCheckpoint {
        return DefaultWorklistCheckpoint(
            code: code,
            title: title,
            threshold: 0.0,
            dosageMg: 0.0,
            allergy: "",
            capacity: 0,
            status: DefaultWorklistCheckpointStatus.draft
        )
    }
}
