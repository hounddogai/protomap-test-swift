import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation slot is in its life cycle.
    enum RevocationSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A revocation slot as the revocation team keeps it.
    final class RevocationSlot {
        var code: String
        var title: String
        var pinned: Bool
        var locale: String
        var refills: Int
        var ward: String
        var quantity: Int
        var timezone: String
        var attempts: Int
        var status: RevocationSlotStatus

        init(code: String, title: String, pinned: Bool, locale: String, refills: Int, ward: String, quantity: Int, timezone: String, attempts: Int, status: RevocationSlotStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.locale = locale
            self.refills = refills
            self.ward = ward
            self.quantity = quantity
            self.timezone = timezone
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RevocationSlotStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RevocationSlotStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RevocationSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("revocation slot") \(code)"
        }

        func weightedValue() -> Double {
            return (Double(refills) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> RevocationSlot {
            return RevocationSlot(
                code: code,
                title: title,
                pinned: pinned,
                locale: locale,
                refills: refills,
                ward: ward,
                quantity: quantity,
                timezone: timezone,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a revocation slot in status created.
    static func newRevocationSlot(_ code: String, title: String) -> RevocationSlot {
        return RevocationSlot(
            code: code,
            title: title,
            pinned: false,
            locale: "",
            refills: 0,
            ward: "",
            quantity: 0,
            timezone: "",
            attempts: 0,
            status: RevocationSlotStatus.created
        )
    }
}
