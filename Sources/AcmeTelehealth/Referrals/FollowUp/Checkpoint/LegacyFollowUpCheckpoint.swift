import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy follow up checkpoint is in its life cycle.
    enum LegacyFollowUpCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A legacy follow up checkpoint. Its code is unique within a tenant.
    final class LegacyFollowUpCheckpoint {
        var code: String
        var name: String
        var active: Bool
        var pinned: Bool
        var title: String
        var acuity: Int
        var channel: String
        var visitMinutes: Int
        var copay: Double
        var status: LegacyFollowUpCheckpointStatus

        init(code: String, name: String, active: Bool, pinned: Bool, title: String, acuity: Int, channel: String, visitMinutes: Int, copay: Double, status: LegacyFollowUpCheckpointStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.pinned = pinned
            self.title = title
            self.acuity = acuity
            self.channel = channel
            self.visitMinutes = visitMinutes
            self.copay = copay
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

        func canMoveTo(_ next: LegacyFollowUpCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyFollowUpCheckpointStatus.scheduled || next == LegacyFollowUpCheckpointStatus.completed
            case .scheduled:
                return next == LegacyFollowUpCheckpointStatus.completed || next == LegacyFollowUpCheckpointStatus.cancelled
            case .inProgress:
                return next == LegacyFollowUpCheckpointStatus.completed || next == LegacyFollowUpCheckpointStatus.cancelled
            case .completed:
                return next == LegacyFollowUpCheckpointStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyFollowUpCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy follow up checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy follow up checkpoint") \(code)"
        }

        func effectiveTotal() -> Double {
            return (Double(acuity) * copay * 100).rounded() / 100
        }

        func copyValue() -> LegacyFollowUpCheckpoint {
            return LegacyFollowUpCheckpoint(
                code: code,
                name: name,
                active: active,
                pinned: pinned,
                title: title,
                acuity: acuity,
                channel: channel,
                visitMinutes: visitMinutes,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a legacy follow up checkpoint in status planned.
    static func newLegacyFollowUpCheckpoint(_ code: String, name: String) -> LegacyFollowUpCheckpoint {
        return LegacyFollowUpCheckpoint(
            code: code,
            name: name,
            active: false,
            pinned: false,
            title: "",
            acuity: 0,
            channel: "",
            visitMinutes: 0,
            copay: 0.0,
            status: LegacyFollowUpCheckpointStatus.planned
        )
    }
}
