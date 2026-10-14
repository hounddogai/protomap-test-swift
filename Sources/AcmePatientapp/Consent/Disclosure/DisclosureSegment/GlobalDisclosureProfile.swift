import AcmePlatform
import Foundation

extension Consent {
    /// Where a global disclosure profile is in its life cycle.
    enum GlobalDisclosureProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A global disclosure profile. Its code is unique within a tenant.
    final class GlobalDisclosureProfile {
        var code: String
        var name: String
        var pinned: Bool
        var payer: String
        var currency: String
        var contactEmail: String
        var category: String
        var startsAt: Int
        var externalRef: String
        var title: String
        var status: GlobalDisclosureProfileStatus

        init(code: String, name: String, pinned: Bool, payer: String, currency: String, contactEmail: String, category: String, startsAt: Int, externalRef: String, title: String, status: GlobalDisclosureProfileStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.payer = payer
            self.currency = currency
            self.contactEmail = contactEmail
            self.category = category
            self.startsAt = startsAt
            self.externalRef = externalRef
            self.title = title
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

        func canMoveTo(_ next: GlobalDisclosureProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalDisclosureProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global disclosure profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> GlobalDisclosureProfile {
            return GlobalDisclosureProfile(
                code: code,
                name: name,
                pinned: pinned,
                payer: payer,
                currency: currency,
                contactEmail: contactEmail,
                category: category,
                startsAt: startsAt,
                externalRef: externalRef,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a global disclosure profile in status draft.
    static func newGlobalDisclosureProfile(_ code: String, name: String) -> GlobalDisclosureProfile {
        return GlobalDisclosureProfile(
            code: code,
            name: name,
            pinned: false,
            payer: "",
            currency: "",
            contactEmail: "",
            category: "",
            startsAt: 0,
            externalRef: "",
            title: "",
            status: GlobalDisclosureProfileStatus.draft
        )
    }
}
