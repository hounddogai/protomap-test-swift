import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched courier batch is in its life cycle.
    enum BatchedCourierBatchStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A batched courier batch as the courier team keeps it.
    final class BatchedCourierBatch {
        var code: String
        var label: String
        var ratio: Double
        var amount: Double
        var contactEmail: String
        var weight: Double
        var minimum: Double
        var limit: Int
        var externalRef: String
        var segment: String
        var ceiling: Double
        var status: BatchedCourierBatchStatus

        init(code: String, label: String, ratio: Double, amount: Double, contactEmail: String, weight: Double, minimum: Double, limit: Int, externalRef: String, segment: String, ceiling: Double, status: BatchedCourierBatchStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.amount = amount
            self.contactEmail = contactEmail
            self.weight = weight
            self.minimum = minimum
            self.limit = limit
            self.externalRef = externalRef
            self.segment = segment
            self.ceiling = ceiling
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

        func canMoveTo(_ next: BatchedCourierBatchStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == BatchedCourierBatchStatus.ready || next == BatchedCourierBatchStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == BatchedCourierBatchStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedCourierBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched courier batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("batched courier batch") \(code)"
        }

        func effectiveVolume() -> Double {
            return (ceiling * ratio * 100).rounded() / 100
        }

        func copyValue() -> BatchedCourierBatch {
            return BatchedCourierBatch(
                code: code,
                label: label,
                ratio: ratio,
                amount: amount,
                contactEmail: contactEmail,
                weight: weight,
                minimum: minimum,
                limit: limit,
                externalRef: externalRef,
                segment: segment,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched courier batch in status idle.
    static func newBatchedCourierBatch(_ code: String, label: String) -> BatchedCourierBatch {
        return BatchedCourierBatch(
            code: code,
            label: label,
            ratio: 0.0,
            amount: 0.0,
            contactEmail: "",
            weight: 0.0,
            minimum: 0.0,
            limit: 0,
            externalRef: "",
            segment: "",
            ceiling: 0.0,
            status: BatchedCourierBatchStatus.idle
        )
    }
}
