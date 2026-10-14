import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped accession checkpoint is in its life cycle.
    enum CappedAccessionCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One capped accession checkpoint, with what the planners need to act on it.
    final class CappedAccessionCheckpoint {
        var code: String
        var name: String
        var attempts: Int
        var visible: Bool
        var patientRef: String
        var status: CappedAccessionCheckpointStatus

        init(code: String, name: String, attempts: Int, visible: Bool, patientRef: String, status: CappedAccessionCheckpointStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.visible = visible
            self.patientRef = patientRef
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

        func canMoveTo(_ next: CappedAccessionCheckpointStatus) -> Bool {
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
                return next == CappedAccessionCheckpointStatus.reopened
            case .resolved:
                return next == CappedAccessionCheckpointStatus.archived
            case .reopened:
                return next == CappedAccessionCheckpointStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedAccessionCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped accession checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> CappedAccessionCheckpoint {
            return CappedAccessionCheckpoint(
                code: code,
                name: name,
                attempts: attempts,
                visible: visible,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped accession checkpoint in status open.
    static func newCappedAccessionCheckpoint(_ code: String, name: String) -> CappedAccessionCheckpoint {
        return CappedAccessionCheckpoint(
            code: code,
            name: name,
            attempts: 0,
            visible: false,
            patientRef: "",
            status: CappedAccessionCheckpointStatus.`open`
        )
    }
}
