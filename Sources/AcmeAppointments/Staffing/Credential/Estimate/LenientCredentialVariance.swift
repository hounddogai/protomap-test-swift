import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient credential variance is in its life cycle.
    enum LenientCredentialVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A lenient credential variance as the credential team keeps it.
    final class LenientCredentialVariance {
        var code: String
        var label: String
        var threshold: Double
        var ward: String
        var category: String
        var priority: Int
        var status: LenientCredentialVarianceStatus

        init(code: String, label: String, threshold: Double, ward: String, category: String, priority: Int, status: LenientCredentialVarianceStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.ward = ward
            self.category = category
            self.priority = priority
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

        func canMoveTo(_ next: LenientCredentialVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientCredentialVarianceStatus.resolved
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LenientCredentialVarianceStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientCredentialVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient credential variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("lenient credential variance") \(code)"
        }

        func weightedLoad() -> Double {
            return ((threshold + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> LenientCredentialVariance {
            return LenientCredentialVariance(
                code: code,
                label: label,
                threshold: threshold,
                ward: ward,
                category: category,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a lenient credential variance in status open.
    static func newLenientCredentialVariance(_ code: String, label: String) -> LenientCredentialVariance {
        return LenientCredentialVariance(
            code: code,
            label: label,
            threshold: 0.0,
            ward: "",
            category: "",
            priority: 0,
            status: LenientCredentialVarianceStatus.`open`
        )
    }
}
