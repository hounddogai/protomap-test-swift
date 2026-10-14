import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral quota is in its life cycle.
    enum ReferralQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One referral quota, with what the planners need to act on it.
    final class ReferralQuota {
        var code: String
        var title: String
        var ward: String
        var checksum: String
        var quantity: Int
        var status: ReferralQuotaStatus

        init(code: String, title: String, ward: String, checksum: String, quantity: Int, status: ReferralQuotaStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.checksum = checksum
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ReferralQuotaStatus.withdrawn
            case .rejected:
                return next == ReferralQuotaStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("referral quota") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ReferralQuota {
            return ReferralQuota(
                code: code,
                title: title,
                ward: ward,
                checksum: checksum,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a referral quota in status proposed.
    static func newReferralQuota(_ code: String, title: String) -> ReferralQuota {
        return ReferralQuota(
            code: code,
            title: title,
            ward: "",
            checksum: "",
            quantity: 0,
            status: ReferralQuotaStatus.proposed
        )
    }
}
