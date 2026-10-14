import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task target is in its life cycle.
    enum TaskTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A task target. Its code is unique within a tenant.
    final class TaskTarget {
        var code: String
        var label: String
        var rate: Double
        var reviewer: String
        var floorValue: Double
        var ownerID: String
        var facility: String
        var region: String
        var tags: [String]
        var status: TaskTargetStatus

        init(code: String, label: String, rate: Double, reviewer: String, floorValue: Double, ownerID: String, facility: String, region: String, tags: [String], status: TaskTargetStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.reviewer = reviewer
            self.floorValue = floorValue
            self.ownerID = ownerID
            self.facility = facility
            self.region = region
            self.tags = tags
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

        func canMoveTo(_ next: TaskTargetStatus) -> Bool {
            switch status {
            case .idle:
                return next == TaskTargetStatus.ready
            case .warming:
                return next == TaskTargetStatus.draining || next == TaskTargetStatus.stopped
            case .ready:
                return next == TaskTargetStatus.stopped
            case .draining:
                return next == TaskTargetStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("task target") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return (floorValue * rate * 100).rounded() / 100
        }

        func copyValue() -> TaskTarget {
            return TaskTarget(
                code: code,
                label: label,
                rate: rate,
                reviewer: reviewer,
                floorValue: floorValue,
                ownerID: ownerID,
                facility: facility,
                region: region,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a task target in status idle.
    static func newTaskTarget(_ code: String, label: String) -> TaskTarget {
        return TaskTarget(
            code: code,
            label: label,
            rate: 0.0,
            reviewer: "",
            floorValue: 0.0,
            ownerID: "",
            facility: "",
            region: "",
            tags: [],
            status: TaskTargetStatus.idle
        )
    }
}
