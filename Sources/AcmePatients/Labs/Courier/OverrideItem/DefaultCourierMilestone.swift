import AcmePlatform
import Foundation

extension Labs {
    /// Where a default courier milestone is in its life cycle.
    enum DefaultCourierMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One default courier milestone, with what the planners need to act on it.
    final class DefaultCourierMilestone {
        var code: String
        var title: String
        var durationMinutes: Int
        var tags: [String]
        var weight: Double
        var floorValue: Double
        var status: DefaultCourierMilestoneStatus

        init(code: String, title: String, durationMinutes: Int, tags: [String], weight: Double, floorValue: Double, status: DefaultCourierMilestoneStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.tags = tags
            self.weight = weight
            self.floorValue = floorValue
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

        func canMoveTo(_ next: DefaultCourierMilestoneStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == DefaultCourierMilestoneStatus.inProgress
            case .inProgress:
                return next == DefaultCourierMilestoneStatus.completed || next == DefaultCourierMilestoneStatus.cancelled
            case .completed:
                return next == DefaultCourierMilestoneStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCourierMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default courier milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedLoad() -> Double {
            return (floorValue * weight * 100).rounded() / 100
        }

        func copyValue() -> DefaultCourierMilestone {
            return DefaultCourierMilestone(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                tags: tags,
                weight: weight,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default courier milestone in status planned.
    static func newDefaultCourierMilestone(_ code: String, title: String) -> DefaultCourierMilestone {
        return DefaultCourierMilestone(
            code: code,
            title: title,
            durationMinutes: 0,
            tags: [],
            weight: 0.0,
            floorValue: 0.0,
            status: DefaultCourierMilestoneStatus.planned
        )
    }
}
