import AcmePlatform
import Foundation

extension Imaging {
    /// Where a batched care protocol threshold is in its life cycle.
    enum BatchedCareProtocolThresholdStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a batched care protocol threshold and its current status.
    final class BatchedCareProtocolThreshold {
        var code: String
        var title: String
        var updatedAt: Int
        var discount: Double
        var sequence: Int
        var timezone: String
        var segment: String
        var status: BatchedCareProtocolThresholdStatus

        init(code: String, title: String, updatedAt: Int, discount: Double, sequence: Int, timezone: String, segment: String, status: BatchedCareProtocolThresholdStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.discount = discount
            self.sequence = sequence
            self.timezone = timezone
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedCareProtocolThresholdStatus) -> Bool {
            switch status {
            case .created:
                return next == BatchedCareProtocolThresholdStatus.validated || next == BatchedCareProtocolThresholdStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == BatchedCareProtocolThresholdStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedCareProtocolThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched care protocol threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return (Double(updatedAt) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCareProtocolThreshold {
            return BatchedCareProtocolThreshold(
                code: code,
                title: title,
                updatedAt: updatedAt,
                discount: discount,
                sequence: sequence,
                timezone: timezone,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched care protocol threshold in status created.
    static func newBatchedCareProtocolThreshold(_ code: String, title: String) -> BatchedCareProtocolThreshold {
        return BatchedCareProtocolThreshold(
            code: code,
            title: title,
            updatedAt: 0,
            discount: 0.0,
            sequence: 0,
            timezone: "",
            segment: "",
            status: BatchedCareProtocolThresholdStatus.created
        )
    }
}
