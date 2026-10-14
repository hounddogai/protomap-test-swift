import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix profile is in its life cycle.
    enum SkillMixProfileStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A skill mix profile. Its code is unique within a tenant.
    final class SkillMixProfile {
        var code: String
        var name: String
        var copay: Double
        var attempts: Int
        var label: String
        var visitMinutes: Int
        var status: SkillMixProfileStatus

        init(code: String, name: String, copay: Double, attempts: Int, label: String, visitMinutes: Int, status: SkillMixProfileStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.attempts = attempts
            self.label = label
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SkillMixProfileStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == SkillMixProfileStatus.published || next == SkillMixProfileStatus.retired
            case .published:
                return next == SkillMixProfileStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func effectiveExposure() -> Double {
            return (Double(attempts) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixProfile {
            return SkillMixProfile(
                code: code,
                name: name,
                copay: copay,
                attempts: attempts,
                label: label,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a skill mix profile in status created.
    static func newSkillMixProfile(_ code: String, name: String) -> SkillMixProfile {
        return SkillMixProfile(
            code: code,
            name: name,
            copay: 0.0,
            attempts: 0,
            label: "",
            visitMinutes: 0,
            status: SkillMixProfileStatus.created
        )
    }
}
