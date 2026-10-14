import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a tiered isolation milestone is in its life cycle.
    enum TieredIsolationMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One tiered isolation milestone, with what the planners need to act on it.
    final class TieredIsolationMilestone {
        var code: String
        var name: String
        var region: String
        var floorValue: Double
        var durationMinutes: Int
        var status: TieredIsolationMilestoneStatus

        init(code: String, name: String, region: String, floorValue: Double, durationMinutes: Int, status: TieredIsolationMilestoneStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.floorValue = floorValue
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: TieredIsolationMilestoneStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredIsolationMilestoneStatus.completed
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == TieredIsolationMilestoneStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredIsolationMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered isolation milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveVolume() -> Double {
            return ((Double(durationMinutes) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> TieredIsolationMilestone {
            return TieredIsolationMilestone(
                code: code,
                name: name,
                region: region,
                floorValue: floorValue,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a tiered isolation milestone in status planned.
    static func newTieredIsolationMilestone(_ code: String, name: String) -> TieredIsolationMilestone {
        return TieredIsolationMilestone(
            code: code,
            name: name,
            region: "",
            floorValue: 0.0,
            durationMinutes: 0,
            status: TieredIsolationMilestoneStatus.planned
        )
    }
}
