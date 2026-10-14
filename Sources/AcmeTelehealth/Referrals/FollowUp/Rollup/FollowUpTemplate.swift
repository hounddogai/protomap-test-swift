import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up template is in its life cycle.
    enum FollowUpTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A follow up template as the follow up team keeps it.
    final class FollowUpTemplate {
        var code: String
        var label: String
        var description: String
        var version: Int
        var refills: Int
        var status: FollowUpTemplateStatus

        init(code: String, label: String, description: String, version: Int, refills: Int, status: FollowUpTemplateStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.version = version
            self.refills = refills
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

        func canMoveTo(_ next: FollowUpTemplateStatus) -> Bool {
            switch status {
            case .draft:
                return next == FollowUpTemplateStatus.pending
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: FollowUpTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("follow up template") \(code)"
        }

        func effectiveLoad() -> Double {
            return (Double(refills) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpTemplate {
            return FollowUpTemplate(
                code: code,
                label: label,
                description: description,
                version: version,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a follow up template in status draft.
    static func newFollowUpTemplate(_ code: String, label: String) -> FollowUpTemplate {
        return FollowUpTemplate(
            code: code,
            label: label,
            description: "",
            version: 0,
            refills: 0,
            status: FollowUpTemplateStatus.draft
        )
    }
}
