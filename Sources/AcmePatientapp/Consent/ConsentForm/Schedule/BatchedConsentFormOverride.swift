import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched consent form override is in its life cycle.
    enum BatchedConsentFormOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One batched consent form override, with what the planners need to act on it.
    final class BatchedConsentFormOverride {
        var code: String
        var title: String
        var batchSize: Int
        var ratio: Double
        var rate: Double
        var status: BatchedConsentFormOverrideStatus

        init(code: String, title: String, batchSize: Int, ratio: Double, rate: Double, status: BatchedConsentFormOverrideStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.ratio = ratio
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedConsentFormOverrideStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == BatchedConsentFormOverrideStatus.done || next == BatchedConsentFormOverrideStatus.failed
            case .running:
                return next == BatchedConsentFormOverrideStatus.done
            case .done:
                return next == BatchedConsentFormOverrideStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedConsentFormOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched consent form override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched consent form override") \(code)"
        }

        func adjustedTotal() -> Double {
            return (rate * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> BatchedConsentFormOverride {
            return BatchedConsentFormOverride(
                code: code,
                title: title,
                batchSize: batchSize,
                ratio: ratio,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched consent form override in status new.
    static func newBatchedConsentFormOverride(_ code: String, title: String) -> BatchedConsentFormOverride {
        return BatchedConsentFormOverride(
            code: code,
            title: title,
            batchSize: 0,
            ratio: 0.0,
            rate: 0.0,
            status: BatchedConsentFormOverrideStatus.new
        )
    }
}
