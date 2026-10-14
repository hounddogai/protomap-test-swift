import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled panel adjustment is in its life cycle.
    enum ScheduledPanelAdjustmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a scheduled panel adjustment and its current status.
    final class ScheduledPanelAdjustment {
        var code: String
        var label: String
        var visible: Bool
        var priority: Int
        var tags: [String]
        var status: ScheduledPanelAdjustmentStatus

        init(code: String, label: String, visible: Bool, priority: Int, tags: [String], status: ScheduledPanelAdjustmentStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.priority = priority
            self.tags = tags
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

        func canMoveTo(_ next: ScheduledPanelAdjustmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledPanelAdjustmentStatus.resolved || next == ScheduledPanelAdjustmentStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
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

        func moveTo(_ next: ScheduledPanelAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled panel adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> ScheduledPanelAdjustment {
            return ScheduledPanelAdjustment(
                code: code,
                label: label,
                visible: visible,
                priority: priority,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled panel adjustment in status open.
    static func newScheduledPanelAdjustment(_ code: String, label: String) -> ScheduledPanelAdjustment {
        return ScheduledPanelAdjustment(
            code: code,
            label: label,
            visible: false,
            priority: 0,
            tags: [],
            status: ScheduledPanelAdjustmentStatus.`open`
        )
    }
}
