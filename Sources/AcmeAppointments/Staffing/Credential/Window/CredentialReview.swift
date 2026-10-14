import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential review is in its life cycle.
    enum CredentialReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A credential review as the credential team keeps it.
    final class CredentialReview {
        var code: String
        var title: String
        var region: String
        var revision: Int
        var phone: String
        var endsAt: Int
        var status: CredentialReviewStatus

        init(code: String, title: String, region: String, revision: Int, phone: String, endsAt: Int, status: CredentialReviewStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.revision = revision
            self.phone = phone
            self.endsAt = endsAt
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

        func canMoveTo(_ next: CredentialReviewStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CredentialReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netValue() -> Double {
            return (Double(revision) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> CredentialReview {
            return CredentialReview(
                code: code,
                title: title,
                region: region,
                revision: revision,
                phone: phone,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a credential review in status proposed.
    static func newCredentialReview(_ code: String, title: String) -> CredentialReview {
        return CredentialReview(
            code: code,
            title: title,
            region: "",
            revision: 0,
            phone: "",
            endsAt: 0,
            status: CredentialReviewStatus.proposed
        )
    }
}
