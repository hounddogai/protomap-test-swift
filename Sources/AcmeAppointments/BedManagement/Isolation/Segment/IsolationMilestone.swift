import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation milestone is in its life cycle.
    enum IsolationMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A isolation milestone. Its code is unique within a tenant.
    final class IsolationMilestone {
        var code: String
        var title: String
        var description: String
        var pinned: Bool
        var capacity: Int
        var ceiling: Double
        var source: String
        var active: Bool
        var threshold: Double
        var status: IsolationMilestoneStatus

        init(code: String, title: String, description: String, pinned: Bool, capacity: Int, ceiling: Double, source: String, active: Bool, threshold: Double, status: IsolationMilestoneStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.pinned = pinned
            self.capacity = capacity
            self.ceiling = ceiling
            self.source = source
            self.active = active
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationMilestoneStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == IsolationMilestoneStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return ((threshold + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> IsolationMilestone {
            return IsolationMilestone(
                code: code,
                title: title,
                description: description,
                pinned: pinned,
                capacity: capacity,
                ceiling: ceiling,
                source: source,
                active: active,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a isolation milestone in status created.
    static func newIsolationMilestone(_ code: String, title: String) -> IsolationMilestone {
        return IsolationMilestone(
            code: code,
            title: title,
            description: "",
            pinned: false,
            capacity: 0,
            ceiling: 0.0,
            source: "",
            active: false,
            threshold: 0.0,
            status: IsolationMilestoneStatus.created
        )
    }
}
