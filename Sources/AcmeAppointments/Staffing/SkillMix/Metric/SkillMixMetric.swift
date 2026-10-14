import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix metric is in its life cycle.
    enum SkillMixMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One skill mix metric, with what the planners need to act on it.
    final class SkillMixMetric {
        var code: String
        var title: String
        var ownerID: String
        var startsAt: Int
        var category: String
        var label: String
        var status: SkillMixMetricStatus

        init(code: String, title: String, ownerID: String, startsAt: Int, category: String, label: String, status: SkillMixMetricStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.startsAt = startsAt
            self.category = category
            self.label = label
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

        func canMoveTo(_ next: SkillMixMetricStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SkillMixMetricStatus.rejected || next == SkillMixMetricStatus.withdrawn
            case .approved:
                return next == SkillMixMetricStatus.withdrawn
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

        func moveTo(_ next: SkillMixMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("skill mix metric") \(code)"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> SkillMixMetric {
            return SkillMixMetric(
                code: code,
                title: title,
                ownerID: ownerID,
                startsAt: startsAt,
                category: category,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a skill mix metric in status proposed.
    static func newSkillMixMetric(_ code: String, title: String) -> SkillMixMetric {
        return SkillMixMetric(
            code: code,
            title: title,
            ownerID: "",
            startsAt: 0,
            category: "",
            label: "",
            status: SkillMixMetricStatus.proposed
        )
    }
}
