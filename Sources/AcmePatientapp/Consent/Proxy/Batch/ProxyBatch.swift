import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy batch is in its life cycle.
    enum ProxyBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a proxy batch and its current status.
    final class ProxyBatch {
        var code: String
        var label: String
        var visitMinutes: Int
        var score: Double
        var capacity: Int
        var maximum: Double
        var allergy: String
        var minimum: Double
        var attempts: Int
        var checksum: String
        var status: ProxyBatchStatus

        init(code: String, label: String, visitMinutes: Int, score: Double, capacity: Int, maximum: Double, allergy: String, minimum: Double, attempts: Int, checksum: String, status: ProxyBatchStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.score = score
            self.capacity = capacity
            self.maximum = maximum
            self.allergy = allergy
            self.minimum = minimum
            self.attempts = attempts
            self.checksum = checksum
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

        func canMoveTo(_ next: ProxyBatchStatus) -> Bool {
            switch status {
            case .planned:
                return next == ProxyBatchStatus.scheduled || next == ProxyBatchStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ProxyBatchStatus.completed || next == ProxyBatchStatus.cancelled
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

        func moveTo(_ next: ProxyBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedLoad() -> Double {
            return ((Double(attempts) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ProxyBatch {
            return ProxyBatch(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                score: score,
                capacity: capacity,
                maximum: maximum,
                allergy: allergy,
                minimum: minimum,
                attempts: attempts,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a proxy batch in status planned.
    static func newProxyBatch(_ code: String, label: String) -> ProxyBatch {
        return ProxyBatch(
            code: code,
            label: label,
            visitMinutes: 0,
            score: 0.0,
            capacity: 0,
            maximum: 0.0,
            allergy: "",
            minimum: 0.0,
            attempts: 0,
            checksum: "",
            status: ProxyBatchStatus.planned
        )
    }
}
