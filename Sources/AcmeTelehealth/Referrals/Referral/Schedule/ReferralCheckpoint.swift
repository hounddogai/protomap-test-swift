import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral checkpoint is in its life cycle.
    enum ReferralCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One referral checkpoint, with what the planners need to act on it.
    final class ReferralCheckpoint {
        var code: String
        var name: String
        var ratio: Double
        var pinned: Bool
        var version: Int
        var status: ReferralCheckpointStatus

        init(code: String, name: String, ratio: Double, pinned: Bool, version: Int, status: ReferralCheckpointStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.pinned = pinned
            self.version = version
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

        func canMoveTo(_ next: ReferralCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ReferralCheckpointStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveLoad() -> Double {
            return ((ratio + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ReferralCheckpoint {
            return ReferralCheckpoint(
                code: code,
                name: name,
                ratio: ratio,
                pinned: pinned,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a referral checkpoint in status idle.
    static func newReferralCheckpoint(_ code: String, name: String) -> ReferralCheckpoint {
        return ReferralCheckpoint(
            code: code,
            name: name,
            ratio: 0.0,
            pinned: false,
            version: 0,
            status: ReferralCheckpointStatus.idle
        )
    }
}
