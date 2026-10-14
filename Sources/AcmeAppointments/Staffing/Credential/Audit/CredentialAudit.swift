import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential audit is in its life cycle.
    enum CredentialAuditStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One credential audit, with what the planners need to act on it.
    final class CredentialAudit {
        var code: String
        var title: String
        var visible: Bool
        var retries: Int
        var patientRef: String
        var quantity: Int
        var status: CredentialAuditStatus

        init(code: String, title: String, visible: Bool, retries: Int, patientRef: String, quantity: Int, status: CredentialAuditStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.retries = retries
            self.patientRef = patientRef
            self.quantity = quantity
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

        func canMoveTo(_ next: CredentialAuditStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CredentialAuditStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == CredentialAuditStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("credential audit") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(retries) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> CredentialAudit {
            return CredentialAudit(
                code: code,
                title: title,
                visible: visible,
                retries: retries,
                patientRef: patientRef,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a credential audit in status open.
    static func newCredentialAudit(_ code: String, title: String) -> CredentialAudit {
        return CredentialAudit(
            code: code,
            title: title,
            visible: false,
            retries: 0,
            patientRef: "",
            quantity: 0,
            status: CredentialAuditStatus.`open`
        )
    }
}
