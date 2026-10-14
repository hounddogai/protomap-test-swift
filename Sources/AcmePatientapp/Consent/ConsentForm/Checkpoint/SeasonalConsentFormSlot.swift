import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal consent form slot is in its life cycle.
    enum SeasonalConsentFormSlotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One seasonal consent form slot, with what the planners need to act on it.
    final class SeasonalConsentFormSlot {
        var code: String
        var label: String
        var currency: String
        var visible: Bool
        var maximum: Double
        var discount: Double
        var contactEmail: String
        var rate: Double
        var status: SeasonalConsentFormSlotStatus

        init(code: String, label: String, currency: String, visible: Bool, maximum: Double, discount: Double, contactEmail: String, rate: Double, status: SeasonalConsentFormSlotStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.visible = visible
            self.maximum = maximum
            self.discount = discount
            self.contactEmail = contactEmail
            self.rate = rate
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

        func canMoveTo(_ next: SeasonalConsentFormSlotStatus) -> Bool {
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
                return next == SeasonalConsentFormSlotStatus.resolved || next == SeasonalConsentFormSlotStatus.archived
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: SeasonalConsentFormSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal consent form slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("seasonal consent form slot") \(code)"
        }

        func effectiveLoad() -> Double {
            return (discount * maximum * 100).rounded() / 100
        }

        func copyValue() -> SeasonalConsentFormSlot {
            return SeasonalConsentFormSlot(
                code: code,
                label: label,
                currency: currency,
                visible: visible,
                maximum: maximum,
                discount: discount,
                contactEmail: contactEmail,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal consent form slot in status open.
    static func newSeasonalConsentFormSlot(_ code: String, label: String) -> SeasonalConsentFormSlot {
        return SeasonalConsentFormSlot(
            code: code,
            label: label,
            currency: "",
            visible: false,
            maximum: 0.0,
            discount: 0.0,
            contactEmail: "",
            rate: 0.0,
            status: SeasonalConsentFormSlotStatus.`open`
        )
    }
}
