import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution baseline is in its life cycle.
    enum SubstitutionBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A substitution baseline as the substitution team keeps it.
    final class SubstitutionBaseline {
        var code: String
        var title: String
        var currency: String
        var checksum: String
        var contactEmail: String
        var diagnosisCode: String
        var score: Double
        var status: SubstitutionBaselineStatus

        init(code: String, title: String, currency: String, checksum: String, contactEmail: String, diagnosisCode: String, score: Double, status: SubstitutionBaselineStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.checksum = checksum
            self.contactEmail = contactEmail
            self.diagnosisCode = diagnosisCode
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SubstitutionBaselineStatus) -> Bool {
            switch status {
            case .created:
                return next == SubstitutionBaselineStatus.published
            case .validated:
                return next == SubstitutionBaselineStatus.published || next == SubstitutionBaselineStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: SubstitutionBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("substitution baseline") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> SubstitutionBaseline {
            return SubstitutionBaseline(
                code: code,
                title: title,
                currency: currency,
                checksum: checksum,
                contactEmail: contactEmail,
                diagnosisCode: diagnosisCode,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a substitution baseline in status created.
    static func newSubstitutionBaseline(_ code: String, title: String) -> SubstitutionBaseline {
        return SubstitutionBaseline(
            code: code,
            title: title,
            currency: "",
            checksum: "",
            contactEmail: "",
            diagnosisCode: "",
            score: 0.0,
            status: SubstitutionBaselineStatus.created
        )
    }
}
