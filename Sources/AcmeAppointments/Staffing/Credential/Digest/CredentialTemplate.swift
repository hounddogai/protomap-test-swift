import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential template is in its life cycle.
    enum CredentialTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A credential template. Its code is unique within a tenant.
    final class CredentialTemplate {
        var code: String
        var name: String
        var phone: String
        var title: String
        var minimum: Double
        var capacity: Int
        var tags: [String]
        var status: CredentialTemplateStatus

        init(code: String, name: String, phone: String, title: String, minimum: Double, capacity: Int, tags: [String], status: CredentialTemplateStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.title = title
            self.minimum = minimum
            self.capacity = capacity
            self.tags = tags
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

        func canMoveTo(_ next: CredentialTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CredentialTemplateStatus.resolved
            case .resolved:
                return next == CredentialTemplateStatus.archived
            case .reopened:
                return next == CredentialTemplateStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return ((Double(capacity) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> CredentialTemplate {
            return CredentialTemplate(
                code: code,
                name: name,
                phone: phone,
                title: title,
                minimum: minimum,
                capacity: capacity,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a credential template in status open.
    static func newCredentialTemplate(_ code: String, name: String) -> CredentialTemplate {
        return CredentialTemplate(
            code: code,
            name: name,
            phone: "",
            title: "",
            minimum: 0.0,
            capacity: 0,
            tags: [],
            status: CredentialTemplateStatus.`open`
        )
    }
}
