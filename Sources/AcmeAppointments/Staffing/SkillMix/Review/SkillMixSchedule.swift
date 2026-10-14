import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix schedule is in its life cycle.
    enum SkillMixScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a skill mix schedule and its current status.
    final class SkillMixSchedule {
        var code: String
        var name: String
        var category: String
        var procedureCode: String
        var copay: Double
        var currency: String
        var durationMinutes: Int
        var status: SkillMixScheduleStatus

        init(code: String, name: String, category: String, procedureCode: String, copay: Double, currency: String, durationMinutes: Int, status: SkillMixScheduleStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.procedureCode = procedureCode
            self.copay = copay
            self.currency = currency
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: SkillMixScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SkillMixScheduleStatus.archived
            case .inReview:
                return next == SkillMixScheduleStatus.archived
            case .resolved:
                return next == SkillMixScheduleStatus.archived
            case .reopened:
                return next == SkillMixScheduleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("skill mix schedule") \(code)"
        }

        func netVolume() -> Double {
            return ((copay + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixSchedule {
            return SkillMixSchedule(
                code: code,
                name: name,
                category: category,
                procedureCode: procedureCode,
                copay: copay,
                currency: currency,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a skill mix schedule in status open.
    static func newSkillMixSchedule(_ code: String, name: String) -> SkillMixSchedule {
        return SkillMixSchedule(
            code: code,
            name: name,
            category: "",
            procedureCode: "",
            copay: 0.0,
            currency: "",
            durationMinutes: 0,
            status: SkillMixScheduleStatus.`open`
        )
    }
}
