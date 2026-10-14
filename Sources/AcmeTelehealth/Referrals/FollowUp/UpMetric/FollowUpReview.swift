import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up review is in its life cycle.
    enum FollowUpReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a follow up review and its current status.
    final class FollowUpReview {
        var code: String
        var label: String
        var clinicianID: String
        var encounterID: String
        var contactEmail: String
        var retries: Int
        var minimum: Double
        var specialty: String
        var status: FollowUpReviewStatus

        init(code: String, label: String, clinicianID: String, encounterID: String, contactEmail: String, retries: Int, minimum: Double, specialty: String, status: FollowUpReviewStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.encounterID = encounterID
            self.contactEmail = contactEmail
            self.retries = retries
            self.minimum = minimum
            self.specialty = specialty
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

        func canMoveTo(_ next: FollowUpReviewStatus) -> Bool {
            switch status {
            case .requested:
                return next == FollowUpReviewStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FollowUpReviewStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("follow up review") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(retries) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpReview {
            return FollowUpReview(
                code: code,
                label: label,
                clinicianID: clinicianID,
                encounterID: encounterID,
                contactEmail: contactEmail,
                retries: retries,
                minimum: minimum,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a follow up review in status requested.
    static func newFollowUpReview(_ code: String, label: String) -> FollowUpReview {
        return FollowUpReview(
            code: code,
            label: label,
            clinicianID: "",
            encounterID: "",
            contactEmail: "",
            retries: 0,
            minimum: 0.0,
            specialty: "",
            status: FollowUpReviewStatus.requested
        )
    }
}
