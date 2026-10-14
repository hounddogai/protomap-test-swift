import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral schedule is in its life cycle.
    enum ReferralScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a referral schedule and its current status.
    final class ReferralSchedule {
        var code: String
        var name: String
        var threshold: Double
        var encounterID: String
        var summary: String
        var contactEmail: String
        var specialty: String
        var quantity: Int
        var status: ReferralScheduleStatus

        init(code: String, name: String, threshold: Double, encounterID: String, summary: String, contactEmail: String, specialty: String, quantity: Int, status: ReferralScheduleStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.encounterID = encounterID
            self.summary = summary
            self.contactEmail = contactEmail
            self.specialty = specialty
            self.quantity = quantity
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

        func canMoveTo(_ next: ReferralScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
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
                return next == ReferralScheduleStatus.reopened || next == ReferralScheduleStatus.archived
            case .reopened:
                return next == ReferralScheduleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedTotal() -> Double {
            return ((threshold + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ReferralSchedule {
            return ReferralSchedule(
                code: code,
                name: name,
                threshold: threshold,
                encounterID: encounterID,
                summary: summary,
                contactEmail: contactEmail,
                specialty: specialty,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a referral schedule in status open.
    static func newReferralSchedule(_ code: String, name: String) -> ReferralSchedule {
        return ReferralSchedule(
            code: code,
            name: name,
            threshold: 0.0,
            encounterID: "",
            summary: "",
            contactEmail: "",
            specialty: "",
            quantity: 0,
            status: ReferralScheduleStatus.`open`
        )
    }
}
