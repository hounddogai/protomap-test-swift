import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending reference range allocation is in its life cycle.
    enum PendingReferenceRangeAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One pending reference range allocation, with what the planners need to act on it.
    final class PendingReferenceRangeAllocation {
        var code: String
        var name: String
        var locale: String
        var summary: String
        var ceiling: Double
        var checksum: String
        var status: PendingReferenceRangeAllocationStatus

        init(code: String, name: String, locale: String, summary: String, ceiling: Double, checksum: String, status: PendingReferenceRangeAllocationStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.summary = summary
            self.ceiling = ceiling
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

        func canMoveTo(_ next: PendingReferenceRangeAllocationStatus) -> Bool {
            switch status {
            case .planned:
                return next == PendingReferenceRangeAllocationStatus.inProgress
            case .scheduled:
                return next == PendingReferenceRangeAllocationStatus.inProgress || next == PendingReferenceRangeAllocationStatus.completed
            case .inProgress:
                return next == PendingReferenceRangeAllocationStatus.cancelled
            case .completed:
                return next == PendingReferenceRangeAllocationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingReferenceRangeAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending reference range allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> PendingReferenceRangeAllocation {
            return PendingReferenceRangeAllocation(
                code: code,
                name: name,
                locale: locale,
                summary: summary,
                ceiling: ceiling,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a pending reference range allocation in status planned.
    static func newPendingReferenceRangeAllocation(_ code: String, name: String) -> PendingReferenceRangeAllocation {
        return PendingReferenceRangeAllocation(
            code: code,
            name: name,
            locale: "",
            summary: "",
            ceiling: 0.0,
            checksum: "",
            status: PendingReferenceRangeAllocationStatus.planned
        )
    }
}
