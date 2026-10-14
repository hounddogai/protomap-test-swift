import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive panel milestone is in its life cycle.
    enum AdaptivePanelMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One adaptive panel milestone, with what the planners need to act on it.
    final class AdaptivePanelMilestone {
        var code: String
        var name: String
        var encounterID: String
        var visible: Bool
        var refills: Int
        var status: AdaptivePanelMilestoneStatus

        init(code: String, name: String, encounterID: String, visible: Bool, refills: Int, status: AdaptivePanelMilestoneStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.visible = visible
            self.refills = refills
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

        func canMoveTo(_ next: AdaptivePanelMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AdaptivePanelMilestoneStatus.ready || next == AdaptivePanelMilestoneStatus.stopped
            case .ready:
                return next == AdaptivePanelMilestoneStatus.draining
            case .draining:
                return next == AdaptivePanelMilestoneStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptivePanelMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive panel milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> AdaptivePanelMilestone {
            return AdaptivePanelMilestone(
                code: code,
                name: name,
                encounterID: encounterID,
                visible: visible,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive panel milestone in status idle.
    static func newAdaptivePanelMilestone(_ code: String, name: String) -> AdaptivePanelMilestone {
        return AdaptivePanelMilestone(
            code: code,
            name: name,
            encounterID: "",
            visible: false,
            refills: 0,
            status: AdaptivePanelMilestoneStatus.idle
        )
    }
}
