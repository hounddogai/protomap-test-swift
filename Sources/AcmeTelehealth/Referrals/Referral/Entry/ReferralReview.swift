import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral review is in its life cycle.
    enum ReferralReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A referral review. Its code is unique within a tenant.
    final class ReferralReview {
        var code: String
        var title: String
        var refills: Int
        var ceiling: Double
        var ward: String
        var facility: String
        var minimum: Double
        var copay: Double
        var contactEmail: String
        var status: ReferralReviewStatus

        init(code: String, title: String, refills: Int, ceiling: Double, ward: String, facility: String, minimum: Double, copay: Double, contactEmail: String, status: ReferralReviewStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.ceiling = ceiling
            self.ward = ward
            self.facility = facility
            self.minimum = minimum
            self.copay = copay
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralReviewStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ReferralReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedTotal() -> Double {
            return ((copay + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> ReferralReview {
            return ReferralReview(
                code: code,
                title: title,
                refills: refills,
                ceiling: ceiling,
                ward: ward,
                facility: facility,
                minimum: minimum,
                copay: copay,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a referral review in status requested.
    static func newReferralReview(_ code: String, title: String) -> ReferralReview {
        return ReferralReview(
            code: code,
            title: title,
            refills: 0,
            ceiling: 0.0,
            ward: "",
            facility: "",
            minimum: 0.0,
            copay: 0.0,
            contactEmail: "",
            status: ReferralReviewStatus.requested
        )
    }
}
