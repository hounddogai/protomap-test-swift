import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix record is in its life cycle.
    enum SkillMixRecordStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A skill mix record. Its code is unique within a tenant.
    final class SkillMixRecord {
        var code: String
        var title: String
        var pinned: Bool
        var bed: String
        var score: Double
        var retries: Int
        var status: SkillMixRecordStatus

        init(code: String, title: String, pinned: Bool, bed: String, score: Double, retries: Int, status: SkillMixRecordStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.bed = bed
            self.score = score
            self.retries = retries
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

        func canMoveTo(_ next: SkillMixRecordStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SkillMixRecordStatus.reopened || next == SkillMixRecordStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == SkillMixRecordStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("skill mix record") \(code)"
        }

        func projectedLoad() -> Double {
            return (Double(retries) * score * 100).rounded() / 100
        }

        func copyValue() -> SkillMixRecord {
            return SkillMixRecord(
                code: code,
                title: title,
                pinned: pinned,
                bed: bed,
                score: score,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a skill mix record in status open.
    static func newSkillMixRecord(_ code: String, title: String) -> SkillMixRecord {
        return SkillMixRecord(
            code: code,
            title: title,
            pinned: false,
            bed: "",
            score: 0.0,
            retries: 0,
            status: SkillMixRecordStatus.`open`
        )
    }
}
