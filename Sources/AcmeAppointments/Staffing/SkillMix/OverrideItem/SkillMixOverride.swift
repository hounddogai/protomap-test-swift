import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix override is in its life cycle.
    enum SkillMixOverrideStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A skill mix override as the skill mix team keeps it.
    final class SkillMixOverride {
        var code: String
        var title: String
        var revision: Int
        var acuity: Int
        var summary: String
        var version: Int
        var threshold: Double
        var refills: Int
        var status: SkillMixOverrideStatus

        init(code: String, title: String, revision: Int, acuity: Int, summary: String, version: Int, threshold: Double, refills: Int, status: SkillMixOverrideStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.acuity = acuity
            self.summary = summary
            self.version = version
            self.threshold = threshold
            self.refills = refills
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

        func canMoveTo(_ next: SkillMixOverrideStatus) -> Bool {
            switch status {
            case .planned:
                return next == SkillMixOverrideStatus.completed
            case .scheduled:
                return next == SkillMixOverrideStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == SkillMixOverrideStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedValue() -> Double {
            return ((Double(refills) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixOverride {
            return SkillMixOverride(
                code: code,
                title: title,
                revision: revision,
                acuity: acuity,
                summary: summary,
                version: version,
                threshold: threshold,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a skill mix override in status planned.
    static func newSkillMixOverride(_ code: String, title: String) -> SkillMixOverride {
        return SkillMixOverride(
            code: code,
            title: title,
            revision: 0,
            acuity: 0,
            summary: "",
            version: 0,
            threshold: 0.0,
            refills: 0,
            status: SkillMixOverrideStatus.planned
        )
    }
}
