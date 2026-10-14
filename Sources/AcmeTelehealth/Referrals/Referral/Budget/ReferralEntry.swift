import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral entry is in its life cycle.
    enum ReferralEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One referral entry, with what the planners need to act on it.
    final class ReferralEntry {
        var code: String
        var name: String
        var locale: String
        var weight: Double
        var acuity: Int
        var notes: String
        var quantity: Int
        var maximum: Double
        var allergy: String
        var ceiling: Double
        var status: ReferralEntryStatus

        init(code: String, name: String, locale: String, weight: Double, acuity: Int, notes: String, quantity: Int, maximum: Double, allergy: String, ceiling: Double, status: ReferralEntryStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.weight = weight
            self.acuity = acuity
            self.notes = notes
            self.quantity = quantity
            self.maximum = maximum
            self.allergy = allergy
            self.ceiling = ceiling
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

        func canMoveTo(_ next: ReferralEntryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ReferralEntryStatus.draining
            case .draining:
                return next == ReferralEntryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("referral entry") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((ceiling + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> ReferralEntry {
            return ReferralEntry(
                code: code,
                name: name,
                locale: locale,
                weight: weight,
                acuity: acuity,
                notes: notes,
                quantity: quantity,
                maximum: maximum,
                allergy: allergy,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a referral entry in status idle.
    static func newReferralEntry(_ code: String, name: String) -> ReferralEntry {
        return ReferralEntry(
            code: code,
            name: name,
            locale: "",
            weight: 0.0,
            acuity: 0,
            notes: "",
            quantity: 0,
            maximum: 0.0,
            allergy: "",
            ceiling: 0.0,
            status: ReferralEntryStatus.idle
        )
    }
}
