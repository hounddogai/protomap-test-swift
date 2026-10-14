import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment policy is in its life cycle.
    enum AssessmentPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A assessment policy. Its code is unique within a tenant.
    final class AssessmentPolicy {
        var code: String
        var title: String
        var windowDays: Int
        var durationMinutes: Int
        var payer: String
        var status: AssessmentPolicyStatus

        init(code: String, title: String, windowDays: Int, durationMinutes: Int, payer: String, status: AssessmentPolicyStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.durationMinutes = durationMinutes
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AssessmentPolicyStatus) -> Bool {
            switch status {
            case .created:
                return next == AssessmentPolicyStatus.published || next == AssessmentPolicyStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AssessmentPolicyStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveTotal() -> Double {
            return ((Double(windowDays) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentPolicy {
            return AssessmentPolicy(
                code: code,
                title: title,
                windowDays: windowDays,
                durationMinutes: durationMinutes,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a assessment policy in status created.
    static func newAssessmentPolicy(_ code: String, title: String) -> AssessmentPolicy {
        return AssessmentPolicy(
            code: code,
            title: title,
            windowDays: 0,
            durationMinutes: 0,
            payer: "",
            status: AssessmentPolicyStatus.created
        )
    }
}
