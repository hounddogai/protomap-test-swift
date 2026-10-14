import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral template is in its life cycle.
    enum ReferralTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One referral template, with what the planners need to act on it.
    final class ReferralTemplate {
        var code: String
        var title: String
        var label: String
        var revision: Int
        var limit: Int
        var status: ReferralTemplateStatus

        init(code: String, title: String, label: String, revision: Int, limit: Int, status: ReferralTemplateStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.revision = revision
            self.limit = limit
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

        func canMoveTo(_ next: ReferralTemplateStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ReferralTemplateStatus.active
            case .active:
                return next == ReferralTemplateStatus.suspended || next == ReferralTemplateStatus.closed
            case .suspended:
                return next == ReferralTemplateStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("referral template") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(limit) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ReferralTemplate {
            return ReferralTemplate(
                code: code,
                title: title,
                label: label,
                revision: revision,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a referral template in status draft.
    static func newReferralTemplate(_ code: String, title: String) -> ReferralTemplate {
        return ReferralTemplate(
            code: code,
            title: title,
            label: "",
            revision: 0,
            limit: 0,
            status: ReferralTemplateStatus.draft
        )
    }
}
