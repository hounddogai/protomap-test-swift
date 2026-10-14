import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral preference is in its life cycle.
    enum ReferralPreferenceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A referral preference as the referral team keeps it.
    final class ReferralPreference {
        var code: String
        var title: String
        var ownerID: String
        var margin: Double
        var facility: String
        var checksum: String
        var status: ReferralPreferenceStatus

        init(code: String, title: String, ownerID: String, margin: Double, facility: String, checksum: String, status: ReferralPreferenceStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.margin = margin
            self.facility = facility
            self.checksum = checksum
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

        func canMoveTo(_ next: ReferralPreferenceStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ReferralPreferenceStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("referral preference") \(code)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> ReferralPreference {
            return ReferralPreference(
                code: code,
                title: title,
                ownerID: ownerID,
                margin: margin,
                facility: facility,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a referral preference in status open.
    static func newReferralPreference(_ code: String, title: String) -> ReferralPreference {
        return ReferralPreference(
            code: code,
            title: title,
            ownerID: "",
            margin: 0.0,
            facility: "",
            checksum: "",
            status: ReferralPreferenceStatus.`open`
        )
    }
}
