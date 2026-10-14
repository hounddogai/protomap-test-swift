import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive priority rollup is in its life cycle.
    enum AdaptivePriorityRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A adaptive priority rollup. Its code is unique within a tenant.
    final class AdaptivePriorityRollup {
        var code: String
        var label: String
        var name: String
        var durationMinutes: Int
        var encounterID: String
        var segment: String
        var floorValue: Double
        var priority: Int
        var capacity: Int
        var tags: [String]
        var status: AdaptivePriorityRollupStatus

        init(code: String, label: String, name: String, durationMinutes: Int, encounterID: String, segment: String, floorValue: Double, priority: Int, capacity: Int, tags: [String], status: AdaptivePriorityRollupStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.durationMinutes = durationMinutes
            self.encounterID = encounterID
            self.segment = segment
            self.floorValue = floorValue
            self.priority = priority
            self.capacity = capacity
            self.tags = tags
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

        func canMoveTo(_ next: AdaptivePriorityRollupStatus) -> Bool {
            switch status {
            case .planned:
                return next == AdaptivePriorityRollupStatus.inProgress || next == AdaptivePriorityRollupStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == AdaptivePriorityRollupStatus.cancelled
            case .completed:
                return next == AdaptivePriorityRollupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptivePriorityRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive priority rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("adaptive priority rollup") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return ((Double(capacity) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptivePriorityRollup {
            return AdaptivePriorityRollup(
                code: code,
                label: label,
                name: name,
                durationMinutes: durationMinutes,
                encounterID: encounterID,
                segment: segment,
                floorValue: floorValue,
                priority: priority,
                capacity: capacity,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive priority rollup in status planned.
    static func newAdaptivePriorityRollup(_ code: String, label: String) -> AdaptivePriorityRollup {
        return AdaptivePriorityRollup(
            code: code,
            label: label,
            name: "",
            durationMinutes: 0,
            encounterID: "",
            segment: "",
            floorValue: 0.0,
            priority: 0,
            capacity: 0,
            tags: [],
            status: AdaptivePriorityRollupStatus.planned
        )
    }
}
