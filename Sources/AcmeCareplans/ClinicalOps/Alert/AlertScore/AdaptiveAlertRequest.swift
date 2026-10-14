import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive alert request is in its life cycle.
    enum AdaptiveAlertRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A adaptive alert request. Its code is unique within a tenant.
    final class AdaptiveAlertRequest {
        var code: String
        var title: String
        var contactEmail: String
        var phone: String
        var clinicianID: String
        var rate: Double
        var tags: [String]
        var summary: String
        var quantity: Int
        var country: String
        var status: AdaptiveAlertRequestStatus

        init(code: String, title: String, contactEmail: String, phone: String, clinicianID: String, rate: Double, tags: [String], summary: String, quantity: Int, country: String, status: AdaptiveAlertRequestStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.phone = phone
            self.clinicianID = clinicianID
            self.rate = rate
            self.tags = tags
            self.summary = summary
            self.quantity = quantity
            self.country = country
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

        func canMoveTo(_ next: AdaptiveAlertRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == AdaptiveAlertRequestStatus.active
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: AdaptiveAlertRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive alert request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func netLoad() -> Double {
            return (Double(quantity) * rate * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveAlertRequest {
            return AdaptiveAlertRequest(
                code: code,
                title: title,
                contactEmail: contactEmail,
                phone: phone,
                clinicianID: clinicianID,
                rate: rate,
                tags: tags,
                summary: summary,
                quantity: quantity,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a adaptive alert request in status draft.
    static func newAdaptiveAlertRequest(_ code: String, title: String) -> AdaptiveAlertRequest {
        return AdaptiveAlertRequest(
            code: code,
            title: title,
            contactEmail: "",
            phone: "",
            clinicianID: "",
            rate: 0.0,
            tags: [],
            summary: "",
            quantity: 0,
            country: "",
            status: AdaptiveAlertRequestStatus.draft
        )
    }
}
