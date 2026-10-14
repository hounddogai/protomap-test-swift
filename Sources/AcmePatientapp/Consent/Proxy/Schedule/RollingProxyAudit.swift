import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling proxy audit is in its life cycle.
    enum RollingProxyAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One rolling proxy audit, with what the planners need to act on it.
    final class RollingProxyAudit {
        var code: String
        var name: String
        var quantity: Int
        var contactEmail: String
        var specialty: String
        var attributes: [String: String]
        var revision: Int
        var status: RollingProxyAuditStatus

        init(code: String, name: String, quantity: Int, contactEmail: String, specialty: String, attributes: [String: String], revision: Int, status: RollingProxyAuditStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.contactEmail = contactEmail
            self.specialty = specialty
            self.attributes = attributes
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

        func canMoveTo(_ next: RollingProxyAuditStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RollingProxyAuditStatus.rejected || next == RollingProxyAuditStatus.withdrawn
            case .approved:
                return next == RollingProxyAuditStatus.rejected || next == RollingProxyAuditStatus.withdrawn
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

        func moveTo(_ next: RollingProxyAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling proxy audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("rolling proxy audit") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedValue() -> Double {
            return (Double(revision) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> RollingProxyAudit {
            return RollingProxyAudit(
                code: code,
                name: name,
                quantity: quantity,
                contactEmail: contactEmail,
                specialty: specialty,
                attributes: attributes,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling proxy audit in status proposed.
    static func newRollingProxyAudit(_ code: String, name: String) -> RollingProxyAudit {
        return RollingProxyAudit(
            code: code,
            name: name,
            quantity: 0,
            contactEmail: "",
            specialty: "",
            attributes: [:],
            revision: 0,
            status: RollingProxyAuditStatus.proposed
        )
    }
}
