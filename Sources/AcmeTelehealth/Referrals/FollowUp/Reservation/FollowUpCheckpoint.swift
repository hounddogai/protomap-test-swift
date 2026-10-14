import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up checkpoint is in its life cycle.
    enum FollowUpCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a follow up checkpoint and its current status.
    final class FollowUpCheckpoint {
        var code: String
        var title: String
        var expiresAt: Int
        var payer: String
        var copay: Double
        var ownerID: String
        var active: Bool
        var status: FollowUpCheckpointStatus

        init(code: String, title: String, expiresAt: Int, payer: String, copay: Double, ownerID: String, active: Bool, status: FollowUpCheckpointStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.payer = payer
            self.copay = copay
            self.ownerID = ownerID
            self.active = active
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

        func canMoveTo(_ next: FollowUpCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                return next == FollowUpCheckpointStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == FollowUpCheckpointStatus.completed || next == FollowUpCheckpointStatus.cancelled
            case .completed:
                return next == FollowUpCheckpointStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("follow up checkpoint") \(code)"
        }

        func effectiveVolume() -> Double {
            return (copay * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpCheckpoint {
            return FollowUpCheckpoint(
                code: code,
                title: title,
                expiresAt: expiresAt,
                payer: payer,
                copay: copay,
                ownerID: ownerID,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a follow up checkpoint in status planned.
    static func newFollowUpCheckpoint(_ code: String, title: String) -> FollowUpCheckpoint {
        return FollowUpCheckpoint(
            code: code,
            title: title,
            expiresAt: 0,
            payer: "",
            copay: 0.0,
            ownerID: "",
            active: false,
            status: FollowUpCheckpointStatus.planned
        )
    }
}
