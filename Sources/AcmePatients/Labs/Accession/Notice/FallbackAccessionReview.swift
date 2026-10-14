import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback accession review is in its life cycle.
    enum FallbackAccessionReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a fallback accession review and its current status.
    final class FallbackAccessionReview {
        var code: String
        var label: String
        var pinned: Bool
        var discount: Double
        var threshold: Double
        var status: FallbackAccessionReviewStatus

        init(code: String, label: String, pinned: Bool, discount: Double, threshold: Double, status: FallbackAccessionReviewStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.discount = discount
            self.threshold = threshold
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

        func canMoveTo(_ next: FallbackAccessionReviewStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: FallbackAccessionReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback accession review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedLoad() -> Double {
            return ((discount + threshold) * 100).rounded() / 100
        }

        func copyValue() -> FallbackAccessionReview {
            return FallbackAccessionReview(
                code: code,
                label: label,
                pinned: pinned,
                discount: discount,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback accession review in status proposed.
    static func newFallbackAccessionReview(_ code: String, label: String) -> FallbackAccessionReview {
        return FallbackAccessionReview(
            code: code,
            label: label,
            pinned: false,
            discount: 0.0,
            threshold: 0.0,
            status: FallbackAccessionReviewStatus.proposed
        )
    }
}
