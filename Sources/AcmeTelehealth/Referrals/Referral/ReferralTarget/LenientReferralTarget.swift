import AcmePlatform
import Foundation

extension Referrals {
    /// Where a lenient referral target is in its life cycle.
    enum LenientReferralTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One lenient referral target, with what the planners need to act on it.
    final class LenientReferralTarget {
        var code: String
        var label: String
        var ownerID: String
        var quantity: Int
        var graceDays: Int
        var description: String
        var clinicianID: String
        var phone: String
        var weight: Double
        var facility: String
        var status: LenientReferralTargetStatus

        init(code: String, label: String, ownerID: String, quantity: Int, graceDays: Int, description: String, clinicianID: String, phone: String, weight: Double, facility: String, status: LenientReferralTargetStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.quantity = quantity
            self.graceDays = graceDays
            self.description = description
            self.clinicianID = clinicianID
            self.phone = phone
            self.weight = weight
            self.facility = facility
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

        func canMoveTo(_ next: LenientReferralTargetStatus) -> Bool {
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
                return next == LenientReferralTargetStatus.draining || next == LenientReferralTargetStatus.stopped
            case .draining:
                return next == LenientReferralTargetStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientReferralTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient referral target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("lenient referral target") \(code)"
        }

        func weightedExposure() -> Double {
            return ((weight - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> LenientReferralTarget {
            return LenientReferralTarget(
                code: code,
                label: label,
                ownerID: ownerID,
                quantity: quantity,
                graceDays: graceDays,
                description: description,
                clinicianID: clinicianID,
                phone: phone,
                weight: weight,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a lenient referral target in status idle.
    static func newLenientReferralTarget(_ code: String, label: String) -> LenientReferralTarget {
        return LenientReferralTarget(
            code: code,
            label: label,
            ownerID: "",
            quantity: 0,
            graceDays: 0,
            description: "",
            clinicianID: "",
            phone: "",
            weight: 0.0,
            facility: "",
            status: LenientReferralTargetStatus.idle
        )
    }
}
