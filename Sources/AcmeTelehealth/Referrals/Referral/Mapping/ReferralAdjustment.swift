import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral adjustment is in its life cycle.
    enum ReferralAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One referral adjustment, with what the planners need to act on it.
    final class ReferralAdjustment {
        var code: String
        var name: String
        var ward: String
        var contactEmail: String
        var unit: String
        var pinned: Bool
        var refills: Int
        var payer: String
        var dosageMg: Double
        var country: String
        var status: ReferralAdjustmentStatus

        init(code: String, name: String, ward: String, contactEmail: String, unit: String, pinned: Bool, refills: Int, payer: String, dosageMg: Double, country: String, status: ReferralAdjustmentStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.contactEmail = contactEmail
            self.unit = unit
            self.pinned = pinned
            self.refills = refills
            self.payer = payer
            self.dosageMg = dosageMg
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ReferralAdjustmentStatus.inProgress || next == ReferralAdjustmentStatus.cancelled
            case .inProgress:
                return next == ReferralAdjustmentStatus.completed
            case .completed:
                return next == ReferralAdjustmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedLoad() -> Double {
            return (dosageMg * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> ReferralAdjustment {
            return ReferralAdjustment(
                code: code,
                name: name,
                ward: ward,
                contactEmail: contactEmail,
                unit: unit,
                pinned: pinned,
                refills: refills,
                payer: payer,
                dosageMg: dosageMg,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a referral adjustment in status planned.
    static func newReferralAdjustment(_ code: String, name: String) -> ReferralAdjustment {
        return ReferralAdjustment(
            code: code,
            name: name,
            ward: "",
            contactEmail: "",
            unit: "",
            pinned: false,
            refills: 0,
            payer: "",
            dosageMg: 0.0,
            country: "",
            status: ReferralAdjustmentStatus.planned
        )
    }
}
