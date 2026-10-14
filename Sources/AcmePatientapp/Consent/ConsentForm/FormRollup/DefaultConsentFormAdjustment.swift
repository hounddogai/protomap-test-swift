import AcmePlatform
import Foundation

extension Consent {
    /// Where a default consent form adjustment is in its life cycle.
    enum DefaultConsentFormAdjustmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One default consent form adjustment, with what the planners need to act on it.
    final class DefaultConsentFormAdjustment {
        var code: String
        var title: String
        var allergy: String
        var description: String
        var contactEmail: String
        var amount: Double
        var status: DefaultConsentFormAdjustmentStatus

        init(code: String, title: String, allergy: String, description: String, contactEmail: String, amount: Double, status: DefaultConsentFormAdjustmentStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.description = description
            self.contactEmail = contactEmail
            self.amount = amount
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

        func canMoveTo(_ next: DefaultConsentFormAdjustmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DefaultConsentFormAdjustmentStatus.ready
            case .ready:
                return next == DefaultConsentFormAdjustmentStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DefaultConsentFormAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default consent form adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> DefaultConsentFormAdjustment {
            return DefaultConsentFormAdjustment(
                code: code,
                title: title,
                allergy: allergy,
                description: description,
                contactEmail: contactEmail,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default consent form adjustment in status idle.
    static func newDefaultConsentFormAdjustment(_ code: String, title: String) -> DefaultConsentFormAdjustment {
        return DefaultConsentFormAdjustment(
            code: code,
            title: title,
            allergy: "",
            description: "",
            contactEmail: "",
            amount: 0.0,
            status: DefaultConsentFormAdjustmentStatus.idle
        )
    }
}
