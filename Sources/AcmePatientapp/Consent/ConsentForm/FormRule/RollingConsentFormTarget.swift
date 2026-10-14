import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling consent form target is in its life cycle.
    enum RollingConsentFormTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One rolling consent form target, with what the planners need to act on it.
    final class RollingConsentFormTarget {
        var code: String
        var name: String
        var phone: String
        var contactEmail: String
        var notes: String
        var pinned: Bool
        var label: String
        var locale: String
        var description: String
        var quantity: Int
        var status: RollingConsentFormTargetStatus

        init(code: String, name: String, phone: String, contactEmail: String, notes: String, pinned: Bool, label: String, locale: String, description: String, quantity: Int, status: RollingConsentFormTargetStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.contactEmail = contactEmail
            self.notes = notes
            self.pinned = pinned
            self.label = label
            self.locale = locale
            self.description = description
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

        func canMoveTo(_ next: RollingConsentFormTargetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RollingConsentFormTargetStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RollingConsentFormTargetStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingConsentFormTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling consent form target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rolling consent form target") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> RollingConsentFormTarget {
            return RollingConsentFormTarget(
                code: code,
                name: name,
                phone: phone,
                contactEmail: contactEmail,
                notes: notes,
                pinned: pinned,
                label: label,
                locale: locale,
                description: description,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rolling consent form target in status open.
    static func newRollingConsentFormTarget(_ code: String, name: String) -> RollingConsentFormTarget {
        return RollingConsentFormTarget(
            code: code,
            name: name,
            phone: "",
            contactEmail: "",
            notes: "",
            pinned: false,
            label: "",
            locale: "",
            description: "",
            quantity: 0,
            status: RollingConsentFormTargetStatus.`open`
        )
    }
}
