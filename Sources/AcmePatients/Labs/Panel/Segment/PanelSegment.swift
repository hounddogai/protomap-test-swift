import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel segment is in its life cycle.
    enum PanelSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One panel segment, with what the planners need to act on it.
    final class PanelSegment {
        var code: String
        var label: String
        var capacity: Int
        var threshold: Double
        var budget: Double
        var status: PanelSegmentStatus

        init(code: String, label: String, capacity: Int, threshold: Double, budget: Double, status: PanelSegmentStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.threshold = threshold
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PanelSegmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == PanelSegmentStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == PanelSegmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return ((budget + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> PanelSegment {
            return PanelSegment(
                code: code,
                label: label,
                capacity: capacity,
                threshold: threshold,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a panel segment in status draft.
    static func newPanelSegment(_ code: String, label: String) -> PanelSegment {
        return PanelSegment(
            code: code,
            label: label,
            capacity: 0,
            threshold: 0.0,
            budget: 0.0,
            status: PanelSegmentStatus.draft
        )
    }
}
