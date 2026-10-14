import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global assessment checkpoint is in its life cycle.
    enum GlobalAssessmentCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a global assessment checkpoint and its current status.
    final class GlobalAssessmentCheckpoint {
        var code: String
        var name: String
        var createdAt: Int
        var visible: Bool
        var version: Int
        var status: GlobalAssessmentCheckpointStatus

        init(code: String, name: String, createdAt: Int, visible: Bool, version: Int, status: GlobalAssessmentCheckpointStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.visible = visible
            self.version = version
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

        func canMoveTo(_ next: GlobalAssessmentCheckpointStatus) -> Bool {
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
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == GlobalAssessmentCheckpointStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalAssessmentCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global assessment checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("global assessment checkpoint") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(version) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalAssessmentCheckpoint {
            return GlobalAssessmentCheckpoint(
                code: code,
                name: name,
                createdAt: createdAt,
                visible: visible,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global assessment checkpoint in status planned.
    static func newGlobalAssessmentCheckpoint(_ code: String, name: String) -> GlobalAssessmentCheckpoint {
        return GlobalAssessmentCheckpoint(
            code: code,
            name: name,
            createdAt: 0,
            visible: false,
            version: 0,
            status: GlobalAssessmentCheckpointStatus.planned
        )
    }
}
