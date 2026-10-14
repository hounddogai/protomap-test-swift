import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding batch is in its life cycle.
    enum RoundingBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rounding batch as the rounding team keeps it.
    final class RoundingBatch {
        var code: String
        var label: String
        var capacity: Int
        var rate: Double
        var description: String
        var status: RoundingBatchStatus

        init(code: String, label: String, capacity: Int, rate: Double, description: String, status: RoundingBatchStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.rate = rate
            self.description = description
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

        func canMoveTo(_ next: RoundingBatchStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RoundingBatchStatus.resolved || next == RoundingBatchStatus.archived
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RoundingBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rounding batch") \(code)"
        }

        func projectedValue() -> Double {
            return (Double(capacity) * rate * 100).rounded() / 100
        }

        func copyValue() -> RoundingBatch {
            return RoundingBatch(
                code: code,
                label: label,
                capacity: capacity,
                rate: rate,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rounding batch in status open.
    static func newRoundingBatch(_ code: String, label: String) -> RoundingBatch {
        return RoundingBatch(
            code: code,
            label: label,
            capacity: 0,
            rate: 0.0,
            description: "",
            status: RoundingBatchStatus.`open`
        )
    }
}
