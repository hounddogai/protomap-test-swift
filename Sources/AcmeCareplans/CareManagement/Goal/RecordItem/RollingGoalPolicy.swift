import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling goal policy is in its life cycle.
    enum RollingGoalPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling goal policy as the goal team keeps it.
    final class RollingGoalPolicy {
        var code: String
        var label: String
        var score: Double
        var active: Bool
        var durationMinutes: Int
        var phone: String
        var tags: [String]
        var status: RollingGoalPolicyStatus

        init(code: String, label: String, score: Double, active: Bool, durationMinutes: Int, phone: String, tags: [String], status: RollingGoalPolicyStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.active = active
            self.durationMinutes = durationMinutes
            self.phone = phone
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingGoalPolicyStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RollingGoalPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling goal policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedLoad() -> Double {
            return ((score - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RollingGoalPolicy {
            return RollingGoalPolicy(
                code: code,
                label: label,
                score: score,
                active: active,
                durationMinutes: durationMinutes,
                phone: phone,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling goal policy in status requested.
    static func newRollingGoalPolicy(_ code: String, label: String) -> RollingGoalPolicy {
        return RollingGoalPolicy(
            code: code,
            label: label,
            score: 0.0,
            active: false,
            durationMinutes: 0,
            phone: "",
            tags: [],
            status: RollingGoalPolicyStatus.requested
        )
    }
}
