import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime milestone is in its life cycle.
    enum OvertimeMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One overtime milestone, with what the planners need to act on it.
    final class OvertimeMilestone {
        var code: String
        var name: String
        var unit: String
        var endsAt: Int
        var label: String
        var createdAt: Int
        var archived: Bool
        var status: OvertimeMilestoneStatus

        init(code: String, name: String, unit: String, endsAt: Int, label: String, createdAt: Int, archived: Bool, status: OvertimeMilestoneStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.endsAt = endsAt
            self.label = label
            self.createdAt = createdAt
            self.archived = archived
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

        func canMoveTo(_ next: OvertimeMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                return next == OvertimeMilestoneStatus.ready
            case .warming:
                return next == OvertimeMilestoneStatus.ready || next == OvertimeMilestoneStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == OvertimeMilestoneStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("overtime milestone") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(createdAt) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeMilestone {
            return OvertimeMilestone(
                code: code,
                name: name,
                unit: unit,
                endsAt: endsAt,
                label: label,
                createdAt: createdAt,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a overtime milestone in status idle.
    static func newOvertimeMilestone(_ code: String, name: String) -> OvertimeMilestone {
        return OvertimeMilestone(
            code: code,
            name: name,
            unit: "",
            endsAt: 0,
            label: "",
            createdAt: 0,
            archived: false,
            status: OvertimeMilestoneStatus.idle
        )
    }
}
