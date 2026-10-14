import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling claim plan is in its life cycle.
    enum RollingClaimPlanStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One rolling claim plan, with what the planners need to act on it.
    final class RollingClaimPlan {
        var code: String
        var title: String
        var patientRef: String
        var pinned: Bool
        var sequence: Int
        var status: RollingClaimPlanStatus

        init(code: String, title: String, patientRef: String, pinned: Bool, sequence: Int, status: RollingClaimPlanStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.pinned = pinned
            self.sequence = sequence
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

        func canMoveTo(_ next: RollingClaimPlanStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RollingClaimPlanStatus.draining
            case .ready:
                return next == RollingClaimPlanStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RollingClaimPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling claim plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(sequence)
        }

        func copyValue() -> RollingClaimPlan {
            return RollingClaimPlan(
                code: code,
                title: title,
                patientRef: patientRef,
                pinned: pinned,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling claim plan in status idle.
    static func newRollingClaimPlan(_ code: String, title: String) -> RollingClaimPlan {
        return RollingClaimPlan(
            code: code,
            title: title,
            patientRef: "",
            pinned: false,
            sequence: 0,
            status: RollingClaimPlanStatus.idle
        )
    }
}
