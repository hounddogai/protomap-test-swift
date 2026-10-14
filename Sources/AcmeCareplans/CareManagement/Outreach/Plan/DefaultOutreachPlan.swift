import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default outreach plan is in its life cycle.
    enum DefaultOutreachPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a default outreach plan and its current status.
    final class DefaultOutreachPlan {
        var code: String
        var title: String
        var summary: String
        var phone: String
        var pinned: Bool
        var revision: Int
        var status: DefaultOutreachPlanStatus

        init(code: String, title: String, summary: String, phone: String, pinned: Bool, revision: Int, status: DefaultOutreachPlanStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.phone = phone
            self.pinned = pinned
            self.revision = revision
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

        func canMoveTo(_ next: DefaultOutreachPlanStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultOutreachPlanStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DefaultOutreachPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default outreach plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> DefaultOutreachPlan {
            return DefaultOutreachPlan(
                code: code,
                title: title,
                summary: summary,
                phone: phone,
                pinned: pinned,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default outreach plan in status proposed.
    static func newDefaultOutreachPlan(_ code: String, title: String) -> DefaultOutreachPlan {
        return DefaultOutreachPlan(
            code: code,
            title: title,
            summary: "",
            phone: "",
            pinned: false,
            revision: 0,
            status: DefaultOutreachPlanStatus.proposed
        )
    }
}
