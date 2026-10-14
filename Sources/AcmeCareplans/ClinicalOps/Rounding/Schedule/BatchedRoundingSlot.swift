import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a batched rounding slot is in its life cycle.
    enum BatchedRoundingSlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a batched rounding slot and its current status.
    final class BatchedRoundingSlot {
        var code: String
        var title: String
        var checksum: String
        var ratio: Double
        var source: String
        var rate: Double
        var refills: Int
        var threshold: Double
        var currency: String
        var graceDays: Int
        var weight: Double
        var status: BatchedRoundingSlotStatus

        init(code: String, title: String, checksum: String, ratio: Double, source: String, rate: Double, refills: Int, threshold: Double, currency: String, graceDays: Int, weight: Double, status: BatchedRoundingSlotStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.ratio = ratio
            self.source = source
            self.rate = rate
            self.refills = refills
            self.threshold = threshold
            self.currency = currency
            self.graceDays = graceDays
            self.weight = weight
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

        func canMoveTo(_ next: BatchedRoundingSlotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: BatchedRoundingSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched rounding slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return (rate * weight * 100).rounded() / 100
        }

        func copyValue() -> BatchedRoundingSlot {
            return BatchedRoundingSlot(
                code: code,
                title: title,
                checksum: checksum,
                ratio: ratio,
                source: source,
                rate: rate,
                refills: refills,
                threshold: threshold,
                currency: currency,
                graceDays: graceDays,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched rounding slot in status idle.
    static func newBatchedRoundingSlot(_ code: String, title: String) -> BatchedRoundingSlot {
        return BatchedRoundingSlot(
            code: code,
            title: title,
            checksum: "",
            ratio: 0.0,
            source: "",
            rate: 0.0,
            refills: 0,
            threshold: 0.0,
            currency: "",
            graceDays: 0,
            weight: 0.0,
            status: BatchedRoundingSlotStatus.idle
        )
    }
}
