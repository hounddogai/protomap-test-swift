import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted skill mix template is in its life cycle.
    enum WeightedSkillMixTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A weighted skill mix template. Its code is unique within a tenant.
    final class WeightedSkillMixTemplate {
        var code: String
        var label: String
        var description: String
        var maximum: Double
        var archived: Bool
        var externalRef: String
        var specialty: String
        var status: WeightedSkillMixTemplateStatus

        init(code: String, label: String, description: String, maximum: Double, archived: Bool, externalRef: String, specialty: String, status: WeightedSkillMixTemplateStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.maximum = maximum
            self.archived = archived
            self.externalRef = externalRef
            self.specialty = specialty
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

        func canMoveTo(_ next: WeightedSkillMixTemplateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == WeightedSkillMixTemplateStatus.completed || next == WeightedSkillMixTemplateStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: WeightedSkillMixTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted skill mix template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> WeightedSkillMixTemplate {
            return WeightedSkillMixTemplate(
                code: code,
                label: label,
                description: description,
                maximum: maximum,
                archived: archived,
                externalRef: externalRef,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted skill mix template in status planned.
    static func newWeightedSkillMixTemplate(_ code: String, label: String) -> WeightedSkillMixTemplate {
        return WeightedSkillMixTemplate(
            code: code,
            label: label,
            description: "",
            maximum: 0.0,
            archived: false,
            externalRef: "",
            specialty: "",
            status: WeightedSkillMixTemplateStatus.planned
        )
    }
}
