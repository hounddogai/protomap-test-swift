import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending panel milestone is in its life cycle.
    enum PendingPanelMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a pending panel milestone and its current status.
    final class PendingPanelMilestone {
        var code: String
        var name: String
        var ceiling: Double
        var version: Int
        var segment: String
        var retries: Int
        var status: PendingPanelMilestoneStatus

        init(code: String, name: String, ceiling: Double, version: Int, segment: String, retries: Int, status: PendingPanelMilestoneStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.version = version
            self.segment = segment
            self.retries = retries
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

        func canMoveTo(_ next: PendingPanelMilestoneStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == PendingPanelMilestoneStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: PendingPanelMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending panel milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveTotal() -> Double {
            return ((ceiling - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> PendingPanelMilestone {
            return PendingPanelMilestone(
                code: code,
                name: name,
                ceiling: ceiling,
                version: version,
                segment: segment,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a pending panel milestone in status created.
    static func newPendingPanelMilestone(_ code: String, name: String) -> PendingPanelMilestone {
        return PendingPanelMilestone(
            code: code,
            name: name,
            ceiling: 0.0,
            version: 0,
            segment: "",
            retries: 0,
            status: PendingPanelMilestoneStatus.created
        )
    }
}
