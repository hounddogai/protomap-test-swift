import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix target is in its life cycle.
    enum SkillMixTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A skill mix target. Its code is unique within a tenant.
    final class SkillMixTarget {
        var code: String
        var name: String
        var ratio: Double
        var margin: Double
        var ownerID: String
        var status: SkillMixTargetStatus

        init(code: String, name: String, ratio: Double, margin: Double, ownerID: String, status: SkillMixTargetStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.margin = margin
            self.ownerID = ownerID
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

        func canMoveTo(_ next: SkillMixTargetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == SkillMixTargetStatus.completed || next == SkillMixTargetStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == SkillMixTargetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("skill mix target") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((ratio + margin) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixTarget {
            return SkillMixTarget(
                code: code,
                name: name,
                ratio: ratio,
                margin: margin,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a skill mix target in status planned.
    static func newSkillMixTarget(_ code: String, name: String) -> SkillMixTarget {
        return SkillMixTarget(
            code: code,
            name: name,
            ratio: 0.0,
            margin: 0.0,
            ownerID: "",
            status: SkillMixTargetStatus.planned
        )
    }
}
