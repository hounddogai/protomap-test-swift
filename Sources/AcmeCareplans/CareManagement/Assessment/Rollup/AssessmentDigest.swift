import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment digest is in its life cycle.
    enum AssessmentDigestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A assessment digest as the assessment team keeps it.
    final class AssessmentDigest {
        var code: String
        var label: String
        var country: String
        var source: String
        var retries: Int
        var status: AssessmentDigestStatus

        init(code: String, label: String, country: String, source: String, retries: Int, status: AssessmentDigestStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.source = source
            self.retries = retries
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

        func canMoveTo(_ next: AssessmentDigestStatus) -> Bool {
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
                return next == AssessmentDigestStatus.reopened || next == AssessmentDigestStatus.archived
            case .reopened:
                return next == AssessmentDigestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("assessment digest") \(code)"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> AssessmentDigest {
            return AssessmentDigest(
                code: code,
                label: label,
                country: country,
                source: source,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a assessment digest in status open.
    static func newAssessmentDigest(_ code: String, label: String) -> AssessmentDigest {
        return AssessmentDigest(
            code: code,
            label: label,
            country: "",
            source: "",
            retries: 0,
            status: AssessmentDigestStatus.`open`
        )
    }
}
