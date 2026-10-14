import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure review is in its life cycle.
    enum DisclosureReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One disclosure review, with what the planners need to act on it.
    final class DisclosureReview {
        var code: String
        var label: String
        var contactEmail: String
        var phone: String
        var retries: Int
        var sequence: Int
        var diagnosisCode: String
        var status: DisclosureReviewStatus

        init(code: String, label: String, contactEmail: String, phone: String, retries: Int, sequence: Int, diagnosisCode: String, status: DisclosureReviewStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.phone = phone
            self.retries = retries
            self.sequence = sequence
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: DisclosureReviewStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DisclosureReviewStatus.rejected
            case .rejected:
                return next == DisclosureReviewStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedLoad() -> Double {
            return ((Double(sequence) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureReview {
            return DisclosureReview(
                code: code,
                label: label,
                contactEmail: contactEmail,
                phone: phone,
                retries: retries,
                sequence: sequence,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a disclosure review in status proposed.
    static func newDisclosureReview(_ code: String, label: String) -> DisclosureReview {
        return DisclosureReview(
            code: code,
            label: label,
            contactEmail: "",
            phone: "",
            retries: 0,
            sequence: 0,
            diagnosisCode: "",
            status: DisclosureReviewStatus.proposed
        )
    }
}
