import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential agreement is in its life cycle.
    enum CredentialAgreementStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A credential agreement as the credential team keeps it.
    final class CredentialAgreement {
        var code: String
        var title: String
        var tags: [String]
        var visitMinutes: Int
        var limit: Int
        var createdAt: Int
        var category: String
        var segment: String
        var updatedAt: Int
        var status: CredentialAgreementStatus

        init(code: String, title: String, tags: [String], visitMinutes: Int, limit: Int, createdAt: Int, category: String, segment: String, updatedAt: Int, status: CredentialAgreementStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.visitMinutes = visitMinutes
            self.limit = limit
            self.createdAt = createdAt
            self.category = category
            self.segment = segment
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: CredentialAgreementStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CredentialAgreementStatus.reopened
            case .resolved:
                return next == CredentialAgreementStatus.reopened
            case .reopened:
                return next == CredentialAgreementStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("credential agreement") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return ((Double(updatedAt) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CredentialAgreement {
            return CredentialAgreement(
                code: code,
                title: title,
                tags: tags,
                visitMinutes: visitMinutes,
                limit: limit,
                createdAt: createdAt,
                category: category,
                segment: segment,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a credential agreement in status open.
    static func newCredentialAgreement(_ code: String, title: String) -> CredentialAgreement {
        return CredentialAgreement(
            code: code,
            title: title,
            tags: [],
            visitMinutes: 0,
            limit: 0,
            createdAt: 0,
            category: "",
            segment: "",
            updatedAt: 0,
            status: CredentialAgreementStatus.`open`
        )
    }
}
