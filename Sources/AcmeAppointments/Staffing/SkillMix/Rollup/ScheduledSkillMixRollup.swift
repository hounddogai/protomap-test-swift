import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled skill mix rollup is in its life cycle.
    enum ScheduledSkillMixRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A scheduled skill mix rollup. Its code is unique within a tenant.
    final class ScheduledSkillMixRollup {
        var code: String
        var title: String
        var unit: String
        var cost: Double
        var refills: Int
        var timezone: String
        var status: ScheduledSkillMixRollupStatus

        init(code: String, title: String, unit: String, cost: Double, refills: Int, timezone: String, status: ScheduledSkillMixRollupStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.cost = cost
            self.refills = refills
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledSkillMixRollupStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledSkillMixRollupStatus.reopened || next == ScheduledSkillMixRollupStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ScheduledSkillMixRollupStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ScheduledSkillMixRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled skill mix rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedVolume() -> Double {
            return ((cost + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledSkillMixRollup {
            return ScheduledSkillMixRollup(
                code: code,
                title: title,
                unit: unit,
                cost: cost,
                refills: refills,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a scheduled skill mix rollup in status open.
    static func newScheduledSkillMixRollup(_ code: String, title: String) -> ScheduledSkillMixRollup {
        return ScheduledSkillMixRollup(
            code: code,
            title: title,
            unit: "",
            cost: 0.0,
            refills: 0,
            timezone: "",
            status: ScheduledSkillMixRollupStatus.`open`
        )
    }
}
