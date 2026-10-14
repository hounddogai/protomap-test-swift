import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment plan is in its life cycle.
    enum AssessmentPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A assessment plan. Its code is unique within a tenant.
    final class AssessmentPlan {
        var code: String
        var title: String
        var checksum: String
        var pinned: Bool
        var archived: Bool
        var score: Double
        var status: AssessmentPlanStatus

        init(code: String, title: String, checksum: String, pinned: Bool, archived: Bool, score: Double, status: AssessmentPlanStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.pinned = pinned
            self.archived = archived
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AssessmentPlanStatus) -> Bool {
            switch status {
            case .new:
                return next == AssessmentPlanStatus.queued
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == AssessmentPlanStatus.done || next == AssessmentPlanStatus.failed
            case .done:
                return next == AssessmentPlanStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("assessment plan") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> AssessmentPlan {
            return AssessmentPlan(
                code: code,
                title: title,
                checksum: checksum,
                pinned: pinned,
                archived: archived,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a assessment plan in status new.
    static func newAssessmentPlan(_ code: String, title: String) -> AssessmentPlan {
        return AssessmentPlan(
            code: code,
            title: title,
            checksum: "",
            pinned: false,
            archived: false,
            score: 0.0,
            status: AssessmentPlanStatus.new
        )
    }
}
