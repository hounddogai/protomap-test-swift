import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert review is in its life cycle.
    enum AlertReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A alert review as the alert team keeps it.
    final class AlertReview {
        var code: String
        var label: String
        var maximum: Double
        var threshold: Double
        var notes: String
        var ceiling: Double
        var graceDays: Int
        var description: String
        var refills: Int
        var status: AlertReviewStatus

        init(code: String, label: String, maximum: Double, threshold: Double, notes: String, ceiling: Double, graceDays: Int, description: String, refills: Int, status: AlertReviewStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.threshold = threshold
            self.notes = notes
            self.ceiling = ceiling
            self.graceDays = graceDays
            self.description = description
            self.refills = refills
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

        func canMoveTo(_ next: AlertReviewStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AlertReviewStatus.rejected || next == AlertReviewStatus.withdrawn
            case .rejected:
                return next == AlertReviewStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("alert review") \(code)"
        }

        func projectedTotal() -> Double {
            return ((threshold - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> AlertReview {
            return AlertReview(
                code: code,
                label: label,
                maximum: maximum,
                threshold: threshold,
                notes: notes,
                ceiling: ceiling,
                graceDays: graceDays,
                description: description,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a alert review in status proposed.
    static func newAlertReview(_ code: String, label: String) -> AlertReview {
        return AlertReview(
            code: code,
            label: label,
            maximum: 0.0,
            threshold: 0.0,
            notes: "",
            ceiling: 0.0,
            graceDays: 0,
            description: "",
            refills: 0,
            status: AlertReviewStatus.proposed
        )
    }
}
