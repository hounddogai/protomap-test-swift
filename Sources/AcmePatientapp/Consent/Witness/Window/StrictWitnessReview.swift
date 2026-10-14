import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict witness review is in its life cycle.
    enum StrictWitnessReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict witness review as the witness team keeps it.
    final class StrictWitnessReview {
        var code: String
        var label: String
        var capacity: Int
        var maximum: Double
        var diagnosisCode: String
        var status: StrictWitnessReviewStatus

        init(code: String, label: String, capacity: Int, maximum: Double, diagnosisCode: String, status: StrictWitnessReviewStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.maximum = maximum
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictWitnessReviewStatus) -> Bool {
            switch status {
            case .draft:
                return next == StrictWitnessReviewStatus.closed
            case .pending:
                return next == StrictWitnessReviewStatus.suspended
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: StrictWitnessReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict witness review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("strict witness review") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((maximum + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> StrictWitnessReview {
            return StrictWitnessReview(
                code: code,
                label: label,
                capacity: capacity,
                maximum: maximum,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict witness review in status draft.
    static func newStrictWitnessReview(_ code: String, label: String) -> StrictWitnessReview {
        return StrictWitnessReview(
            code: code,
            label: label,
            capacity: 0,
            maximum: 0.0,
            diagnosisCode: "",
            status: StrictWitnessReviewStatus.draft
        )
    }
}
