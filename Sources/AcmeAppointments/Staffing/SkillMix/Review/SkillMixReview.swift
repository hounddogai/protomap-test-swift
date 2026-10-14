import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix review is in its life cycle.
    enum SkillMixReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a skill mix review and its current status.
    final class SkillMixReview {
        var code: String
        var name: String
        var description: String
        var attempts: Int
        var windowDays: Int
        var bed: String
        var refills: Int
        var encounterID: String
        var procedureCode: String
        var visitMinutes: Int
        var visible: Bool
        var status: SkillMixReviewStatus

        init(code: String, name: String, description: String, attempts: Int, windowDays: Int, bed: String, refills: Int, encounterID: String, procedureCode: String, visitMinutes: Int, visible: Bool, status: SkillMixReviewStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.attempts = attempts
            self.windowDays = windowDays
            self.bed = bed
            self.refills = refills
            self.encounterID = encounterID
            self.procedureCode = procedureCode
            self.visitMinutes = visitMinutes
            self.visible = visible
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

        func canMoveTo(_ next: SkillMixReviewStatus) -> Bool {
            switch status {
            case .draft:
                return next == SkillMixReviewStatus.pending || next == SkillMixReviewStatus.closed
            case .pending:
                return next == SkillMixReviewStatus.suspended || next == SkillMixReviewStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == SkillMixReviewStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netLoad() -> Double {
            return (Double(visitMinutes) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixReview {
            return SkillMixReview(
                code: code,
                name: name,
                description: description,
                attempts: attempts,
                windowDays: windowDays,
                bed: bed,
                refills: refills,
                encounterID: encounterID,
                procedureCode: procedureCode,
                visitMinutes: visitMinutes,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a skill mix review in status draft.
    static func newSkillMixReview(_ code: String, name: String) -> SkillMixReview {
        return SkillMixReview(
            code: code,
            name: name,
            description: "",
            attempts: 0,
            windowDays: 0,
            bed: "",
            refills: 0,
            encounterID: "",
            procedureCode: "",
            visitMinutes: 0,
            visible: false,
            status: SkillMixReviewStatus.draft
        )
    }
}
