import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix window is in its life cycle.
    enum SkillMixWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A skill mix window. Its code is unique within a tenant.
    final class SkillMixWindow {
        var code: String
        var title: String
        var clinicianID: String
        var maximum: Double
        var source: String
        var cost: Double
        var acuity: Int
        var status: SkillMixWindowStatus

        init(code: String, title: String, clinicianID: String, maximum: Double, source: String, cost: Double, acuity: Int, status: SkillMixWindowStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.maximum = maximum
            self.source = source
            self.cost = cost
            self.acuity = acuity
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

        func canMoveTo(_ next: SkillMixWindowStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == SkillMixWindowStatus.inProgress
            case .inProgress:
                return next == SkillMixWindowStatus.completed || next == SkillMixWindowStatus.cancelled
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

        func moveTo(_ next: SkillMixWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedLoad() -> Double {
            return (cost * maximum * 100).rounded() / 100
        }

        func copyValue() -> SkillMixWindow {
            return SkillMixWindow(
                code: code,
                title: title,
                clinicianID: clinicianID,
                maximum: maximum,
                source: source,
                cost: cost,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a skill mix window in status planned.
    static func newSkillMixWindow(_ code: String, title: String) -> SkillMixWindow {
        return SkillMixWindow(
            code: code,
            title: title,
            clinicianID: "",
            maximum: 0.0,
            source: "",
            cost: 0.0,
            acuity: 0,
            status: SkillMixWindowStatus.planned
        )
    }
}
