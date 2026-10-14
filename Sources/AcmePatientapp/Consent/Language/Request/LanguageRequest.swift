import AcmePlatform
import Foundation

extension Consent {
    /// Where a language request is in its life cycle.
    enum LanguageRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A language request. Its code is unique within a tenant.
    final class LanguageRequest {
        var code: String
        var title: String
        var phone: String
        var country: String
        var specialty: String
        var ceiling: Double
        var contactEmail: String
        var weight: Double
        var status: LanguageRequestStatus

        init(code: String, title: String, phone: String, country: String, specialty: String, ceiling: Double, contactEmail: String, weight: Double, status: LanguageRequestStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.country = country
            self.specialty = specialty
            self.ceiling = ceiling
            self.contactEmail = contactEmail
            self.weight = weight
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

        func canMoveTo(_ next: LanguageRequestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LanguageRequestStatus.resolved
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LanguageRequestStatus.archived
            case .reopened:
                return next == LanguageRequestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netTotal() -> Double {
            return ((weight - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> LanguageRequest {
            return LanguageRequest(
                code: code,
                title: title,
                phone: phone,
                country: country,
                specialty: specialty,
                ceiling: ceiling,
                contactEmail: contactEmail,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a language request in status open.
    static func newLanguageRequest(_ code: String, title: String) -> LanguageRequest {
        return LanguageRequest(
            code: code,
            title: title,
            phone: "",
            country: "",
            specialty: "",
            ceiling: 0.0,
            contactEmail: "",
            weight: 0.0,
            status: LanguageRequestStatus.`open`
        )
    }
}
