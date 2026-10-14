import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched proxy threshold is in its life cycle.
    enum BatchedProxyThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A batched proxy threshold as the proxy team keeps it.
    final class BatchedProxyThreshold {
        var code: String
        var label: String
        var windowDays: Int
        var expiresAt: Int
        var version: Int
        var maximum: Double
        var status: BatchedProxyThresholdStatus

        init(code: String, label: String, windowDays: Int, expiresAt: Int, version: Int, maximum: Double, status: BatchedProxyThresholdStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.expiresAt = expiresAt
            self.version = version
            self.maximum = maximum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedProxyThresholdStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == BatchedProxyThresholdStatus.inProgress || next == BatchedProxyThresholdStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: BatchedProxyThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched proxy threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveVolume() -> Double {
            return ((Double(expiresAt) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedProxyThreshold {
            return BatchedProxyThreshold(
                code: code,
                label: label,
                windowDays: windowDays,
                expiresAt: expiresAt,
                version: version,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched proxy threshold in status planned.
    static func newBatchedProxyThreshold(_ code: String, label: String) -> BatchedProxyThreshold {
        return BatchedProxyThreshold(
            code: code,
            label: label,
            windowDays: 0,
            expiresAt: 0,
            version: 0,
            maximum: 0.0,
            status: BatchedProxyThresholdStatus.planned
        )
    }
}
