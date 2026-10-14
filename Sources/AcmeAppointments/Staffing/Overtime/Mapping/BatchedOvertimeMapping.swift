import AcmePlatform
import Foundation

extension Staffing {
    /// Where a batched overtime mapping is in its life cycle.
    enum BatchedOvertimeMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a batched overtime mapping and its current status.
    final class BatchedOvertimeMapping {
        var code: String
        var label: String
        var priority: Int
        var createdAt: Int
        var description: String
        var visitMinutes: Int
        var status: BatchedOvertimeMappingStatus

        init(code: String, label: String, priority: Int, createdAt: Int, description: String, visitMinutes: Int, status: BatchedOvertimeMappingStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.createdAt = createdAt
            self.description = description
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: BatchedOvertimeMappingStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == BatchedOvertimeMappingStatus.completed || next == BatchedOvertimeMappingStatus.cancelled
            case .inProgress:
                return next == BatchedOvertimeMappingStatus.completed || next == BatchedOvertimeMappingStatus.cancelled
            case .completed:
                return next == BatchedOvertimeMappingStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedOvertimeMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched overtime mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedVolume() -> Double {
            return ((Double(priority) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedOvertimeMapping {
            return BatchedOvertimeMapping(
                code: code,
                label: label,
                priority: priority,
                createdAt: createdAt,
                description: description,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched overtime mapping in status planned.
    static func newBatchedOvertimeMapping(_ code: String, label: String) -> BatchedOvertimeMapping {
        return BatchedOvertimeMapping(
            code: code,
            label: label,
            priority: 0,
            createdAt: 0,
            description: "",
            visitMinutes: 0,
            status: BatchedOvertimeMappingStatus.planned
        )
    }
}
