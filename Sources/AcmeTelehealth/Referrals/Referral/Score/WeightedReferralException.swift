import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted referral exception is in its life cycle.
    enum WeightedReferralExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A weighted referral exception as the referral team keeps it.
    final class WeightedReferralException {
        var code: String
        var title: String
        var description: String
        var attempts: Int
        var clinicianID: String
        var locale: String
        var refills: Int
        var segment: String
        var notes: String
        var label: String
        var status: WeightedReferralExceptionStatus

        init(code: String, title: String, description: String, attempts: Int, clinicianID: String, locale: String, refills: Int, segment: String, notes: String, label: String, status: WeightedReferralExceptionStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.attempts = attempts
            self.clinicianID = clinicianID
            self.locale = locale
            self.refills = refills
            self.segment = segment
            self.notes = notes
            self.label = label
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

        func canMoveTo(_ next: WeightedReferralExceptionStatus) -> Bool {
            switch status {
            case .idle:
                return next == WeightedReferralExceptionStatus.stopped
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == WeightedReferralExceptionStatus.draining || next == WeightedReferralExceptionStatus.stopped
            case .draining:
                return next == WeightedReferralExceptionStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedReferralExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted referral exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func netExposure() -> Double {
            return ((Double(attempts) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedReferralException {
            return WeightedReferralException(
                code: code,
                title: title,
                description: description,
                attempts: attempts,
                clinicianID: clinicianID,
                locale: locale,
                refills: refills,
                segment: segment,
                notes: notes,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a weighted referral exception in status idle.
    static func newWeightedReferralException(_ code: String, title: String) -> WeightedReferralException {
        return WeightedReferralException(
            code: code,
            title: title,
            description: "",
            attempts: 0,
            clinicianID: "",
            locale: "",
            refills: 0,
            segment: "",
            notes: "",
            label: "",
            status: WeightedReferralExceptionStatus.idle
        )
    }
}
