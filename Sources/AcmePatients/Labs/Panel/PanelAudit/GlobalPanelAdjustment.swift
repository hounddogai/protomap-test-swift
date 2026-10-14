import AcmePlatform
import Foundation

extension Labs {
    /// Where a global panel adjustment is in its life cycle.
    enum GlobalPanelAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global panel adjustment as the panel team keeps it.
    final class GlobalPanelAdjustment {
        var code: String
        var title: String
        var reviewer: String
        var acuity: Int
        var maximum: Double
        var status: GlobalPanelAdjustmentStatus

        init(code: String, title: String, reviewer: String, acuity: Int, maximum: Double, status: GlobalPanelAdjustmentStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.acuity = acuity
            self.maximum = maximum
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

        func canMoveTo(_ next: GlobalPanelAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == GlobalPanelAdjustmentStatus.completed
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == GlobalPanelAdjustmentStatus.completed || next == GlobalPanelAdjustmentStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: GlobalPanelAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global panel adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveTotal() -> Double {
            return (maximum * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> GlobalPanelAdjustment {
            return GlobalPanelAdjustment(
                code: code,
                title: title,
                reviewer: reviewer,
                acuity: acuity,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global panel adjustment in status planned.
    static func newGlobalPanelAdjustment(_ code: String, title: String) -> GlobalPanelAdjustment {
        return GlobalPanelAdjustment(
            code: code,
            title: title,
            reviewer: "",
            acuity: 0,
            maximum: 0.0,
            status: GlobalPanelAdjustmentStatus.planned
        )
    }
}
