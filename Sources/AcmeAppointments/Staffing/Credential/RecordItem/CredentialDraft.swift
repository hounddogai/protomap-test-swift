import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential draft is in its life cycle.
    enum CredentialDraftStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A credential draft as the credential team keeps it.
    final class CredentialDraft {
        var code: String
        var title: String
        var tags: [String]
        var contactEmail: String
        var payer: String
        var quantity: Int
        var status: CredentialDraftStatus

        init(code: String, title: String, tags: [String], contactEmail: String, payer: String, quantity: Int, status: CredentialDraftStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.contactEmail = contactEmail
            self.payer = payer
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CredentialDraftStatus) -> Bool {
            switch status {
            case .idle:
                return next == CredentialDraftStatus.warming || next == CredentialDraftStatus.ready
            case .warming:
                return next == CredentialDraftStatus.ready || next == CredentialDraftStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == CredentialDraftStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> CredentialDraft {
            return CredentialDraft(
                code: code,
                title: title,
                tags: tags,
                contactEmail: contactEmail,
                payer: payer,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a credential draft in status idle.
    static func newCredentialDraft(_ code: String, title: String) -> CredentialDraft {
        return CredentialDraft(
            code: code,
            title: title,
            tags: [],
            contactEmail: "",
            payer: "",
            quantity: 0,
            status: CredentialDraftStatus.idle
        )
    }
}
