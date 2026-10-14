import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix notice is in its life cycle.
    enum SkillMixNoticeStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A skill mix notice as the skill mix team keeps it.
    final class SkillMixNotice {
        var code: String
        var name: String
        var minimum: Double
        var timezone: String
        var acuity: Int
        var category: String
        var batchSize: Int
        var budget: Double
        var bed: String
        var status: SkillMixNoticeStatus

        init(code: String, name: String, minimum: Double, timezone: String, acuity: Int, category: String, batchSize: Int, budget: Double, bed: String, status: SkillMixNoticeStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.timezone = timezone
            self.acuity = acuity
            self.category = category
            self.batchSize = batchSize
            self.budget = budget
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SkillMixNoticeStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == SkillMixNoticeStatus.suspended || next == SkillMixNoticeStatus.closed
            case .suspended:
                return next == SkillMixNoticeStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedTotal() -> Double {
            return ((Double(acuity) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixNotice {
            return SkillMixNotice(
                code: code,
                name: name,
                minimum: minimum,
                timezone: timezone,
                acuity: acuity,
                category: category,
                batchSize: batchSize,
                budget: budget,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a skill mix notice in status draft.
    static func newSkillMixNotice(_ code: String, name: String) -> SkillMixNotice {
        return SkillMixNotice(
            code: code,
            name: name,
            minimum: 0.0,
            timezone: "",
            acuity: 0,
            category: "",
            batchSize: 0,
            budget: 0.0,
            bed: "",
            status: SkillMixNoticeStatus.draft
        )
    }
}
