import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient program plan is in its life cycle.
    enum LenientProgramPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A lenient program plan. Its code is unique within a tenant.
    final class LenientProgramPlan {
        var code: String
        var name: String
        var timezone: String
        var score: Double
        var revision: Int
        var attempts: Int
        var status: LenientProgramPlanStatus

        init(code: String, name: String, timezone: String, score: Double, revision: Int, attempts: Int, status: LenientProgramPlanStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.score = score
            self.revision = revision
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientProgramPlanStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LenientProgramPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient program plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("lenient program plan") \(code)"
        }

        func effectiveVolume() -> Double {
            return (Double(attempts) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> LenientProgramPlan {
            return LenientProgramPlan(
                code: code,
                name: name,
                timezone: timezone,
                score: score,
                revision: revision,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient program plan in status proposed.
    static func newLenientProgramPlan(_ code: String, name: String) -> LenientProgramPlan {
        return LenientProgramPlan(
            code: code,
            name: name,
            timezone: "",
            score: 0.0,
            revision: 0,
            attempts: 0,
            status: LenientProgramPlanStatus.proposed
        )
    }
}
