import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled assessment policy is in its life cycle.
    enum ScheduledAssessmentPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One scheduled assessment policy, with what the planners need to act on it.
    final class ScheduledAssessmentPolicy {
        var code: String
        var title: String
        var locale: String
        var ratio: Double
        var active: Bool
        var rate: Double
        var phone: String
        var weight: Double
        var priority: Int
        var archived: Bool
        var status: ScheduledAssessmentPolicyStatus

        init(code: String, title: String, locale: String, ratio: Double, active: Bool, rate: Double, phone: String, weight: Double, priority: Int, archived: Bool, status: ScheduledAssessmentPolicyStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.ratio = ratio
            self.active = active
            self.rate = rate
            self.phone = phone
            self.weight = weight
            self.priority = priority
            self.archived = archived
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

        func canMoveTo(_ next: ScheduledAssessmentPolicyStatus) -> Bool {
            switch status {
            case .draft:
                return next == ScheduledAssessmentPolicyStatus.pending || next == ScheduledAssessmentPolicyStatus.suspended
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ScheduledAssessmentPolicyStatus.suspended || next == ScheduledAssessmentPolicyStatus.closed
            case .suspended:
                return next == ScheduledAssessmentPolicyStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledAssessmentPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled assessment policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled assessment policy") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((rate - ratio) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAssessmentPolicy {
            return ScheduledAssessmentPolicy(
                code: code,
                title: title,
                locale: locale,
                ratio: ratio,
                active: active,
                rate: rate,
                phone: phone,
                weight: weight,
                priority: priority,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a scheduled assessment policy in status draft.
    static func newScheduledAssessmentPolicy(_ code: String, title: String) -> ScheduledAssessmentPolicy {
        return ScheduledAssessmentPolicy(
            code: code,
            title: title,
            locale: "",
            ratio: 0.0,
            active: false,
            rate: 0.0,
            phone: "",
            weight: 0.0,
            priority: 0,
            archived: false,
            status: ScheduledAssessmentPolicyStatus.draft
        )
    }
}
