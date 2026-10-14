import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict slot checkpoint is in its life cycle.
    enum StrictSlotCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A strict slot checkpoint. Its code is unique within a tenant.
    final class StrictSlotCheckpoint {
        var code: String
        var title: String
        var startsAt: Int
        var acuity: Int
        var copay: Double
        var status: StrictSlotCheckpointStatus

        init(code: String, title: String, startsAt: Int, acuity: Int, copay: Double, status: StrictSlotCheckpointStatus) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.acuity = acuity
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictSlotCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                return next == StrictSlotCheckpointStatus.draining
            case .warming:
                return next == StrictSlotCheckpointStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == StrictSlotCheckpointStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictSlotCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict slot checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netLoad() -> Double {
            return (Double(startsAt) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> StrictSlotCheckpoint {
            return StrictSlotCheckpoint(
                code: code,
                title: title,
                startsAt: startsAt,
                acuity: acuity,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict slot checkpoint in status idle.
    static func newStrictSlotCheckpoint(_ code: String, title: String) -> StrictSlotCheckpoint {
        return StrictSlotCheckpoint(
            code: code,
            title: title,
            startsAt: 0,
            acuity: 0,
            copay: 0.0,
            status: StrictSlotCheckpointStatus.idle
        )
    }
}
