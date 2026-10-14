import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback accession batch is in its life cycle.
    enum FallbackAccessionBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A fallback accession batch. Its code is unique within a tenant.
    final class FallbackAccessionBatch {
        var code: String
        var title: String
        var sequence: Int
        var maximum: Double
        var version: Int
        var limit: Int
        var status: FallbackAccessionBatchStatus

        init(code: String, title: String, sequence: Int, maximum: Double, version: Int, limit: Int, status: FallbackAccessionBatchStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.maximum = maximum
            self.version = version
            self.limit = limit
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

        func canMoveTo(_ next: FallbackAccessionBatchStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == FallbackAccessionBatchStatus.done
            case .running:
                return next == FallbackAccessionBatchStatus.done || next == FallbackAccessionBatchStatus.failed
            case .done:
                return next == FallbackAccessionBatchStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackAccessionBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback accession batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netVolume() -> Double {
            return ((maximum + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackAccessionBatch {
            return FallbackAccessionBatch(
                code: code,
                title: title,
                sequence: sequence,
                maximum: maximum,
                version: version,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback accession batch in status new.
    static func newFallbackAccessionBatch(_ code: String, title: String) -> FallbackAccessionBatch {
        return FallbackAccessionBatch(
            code: code,
            title: title,
            sequence: 0,
            maximum: 0.0,
            version: 0,
            limit: 0,
            status: FallbackAccessionBatchStatus.new
        )
    }
}
