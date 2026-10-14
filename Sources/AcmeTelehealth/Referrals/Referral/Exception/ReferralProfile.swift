import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral profile is in its life cycle.
    enum ReferralProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A referral profile. Its code is unique within a tenant.
    final class ReferralProfile {
        var code: String
        var label: String
        var rate: Double
        var title: String
        var maximum: Double
        var clinicianID: String
        var approved: Bool
        var retries: Int
        var endsAt: Int
        var procedureCode: String
        var status: ReferralProfileStatus

        init(code: String, label: String, rate: Double, title: String, maximum: Double, clinicianID: String, approved: Bool, retries: Int, endsAt: Int, procedureCode: String, status: ReferralProfileStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.title = title
            self.maximum = maximum
            self.clinicianID = clinicianID
            self.approved = approved
            self.retries = retries
            self.endsAt = endsAt
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: ReferralProfileStatus) -> Bool {
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
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ReferralProfileStatus.reopened || next == ReferralProfileStatus.archived
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

        func moveTo(_ next: ReferralProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("referral profile") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(retries) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> ReferralProfile {
            return ReferralProfile(
                code: code,
                label: label,
                rate: rate,
                title: title,
                maximum: maximum,
                clinicianID: clinicianID,
                approved: approved,
                retries: retries,
                endsAt: endsAt,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a referral profile in status open.
    static func newReferralProfile(_ code: String, label: String) -> ReferralProfile {
        return ReferralProfile(
            code: code,
            label: label,
            rate: 0.0,
            title: "",
            maximum: 0.0,
            clinicianID: "",
            approved: false,
            retries: 0,
            endsAt: 0,
            procedureCode: "",
            status: ReferralProfileStatus.`open`
        )
    }
}
