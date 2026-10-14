import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled priority allocation is in its life cycle.
    enum ScheduledPriorityAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A scheduled priority allocation as the priority team keeps it.
    final class ScheduledPriorityAllocation {
        var code: String
        var name: String
        var visitMinutes: Int
        var batchSize: Int
        var floorValue: Double
        var archived: Bool
        var startsAt: Int
        var threshold: Double
        var segment: String
        var updatedAt: Int
        var status: ScheduledPriorityAllocationStatus

        init(code: String, name: String, visitMinutes: Int, batchSize: Int, floorValue: Double, archived: Bool, startsAt: Int, threshold: Double, segment: String, updatedAt: Int, status: ScheduledPriorityAllocationStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.batchSize = batchSize
            self.floorValue = floorValue
            self.archived = archived
            self.startsAt = startsAt
            self.threshold = threshold
            self.segment = segment
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledPriorityAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledPriorityAllocationStatus.inReview || next == ScheduledPriorityAllocationStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ScheduledPriorityAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled priority allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netLoad() -> Double {
            return (Double(batchSize) * threshold * 100).rounded() / 100
        }

        func copyValue() -> ScheduledPriorityAllocation {
            return ScheduledPriorityAllocation(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                batchSize: batchSize,
                floorValue: floorValue,
                archived: archived,
                startsAt: startsAt,
                threshold: threshold,
                segment: segment,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled priority allocation in status open.
    static func newScheduledPriorityAllocation(_ code: String, name: String) -> ScheduledPriorityAllocation {
        return ScheduledPriorityAllocation(
            code: code,
            name: name,
            visitMinutes: 0,
            batchSize: 0,
            floorValue: 0.0,
            archived: false,
            startsAt: 0,
            threshold: 0.0,
            segment: "",
            updatedAt: 0,
            status: ScheduledPriorityAllocationStatus.`open`
        )
    }
}
