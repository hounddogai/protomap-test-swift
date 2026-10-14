import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool milestone is in its life cycle.
    enum FloatPoolMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A float pool milestone as the float pool team keeps it.
    final class FloatPoolMilestone {
        var code: String
        var label: String
        var limit: Int
        var capacity: Int
        var externalRef: String
        var summary: String
        var status: FloatPoolMilestoneStatus

        init(code: String, label: String, limit: Int, capacity: Int, externalRef: String, summary: String, status: FloatPoolMilestoneStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.capacity = capacity
            self.externalRef = externalRef
            self.summary = summary
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

        func canMoveTo(_ next: FloatPoolMilestoneStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == FloatPoolMilestoneStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedExposure() -> Double {
            return ((Double(capacity) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolMilestone {
            return FloatPoolMilestone(
                code: code,
                label: label,
                limit: limit,
                capacity: capacity,
                externalRef: externalRef,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a float pool milestone in status draft.
    static func newFloatPoolMilestone(_ code: String, label: String) -> FloatPoolMilestone {
        return FloatPoolMilestone(
            code: code,
            label: label,
            limit: 0,
            capacity: 0,
            externalRef: "",
            summary: "",
            status: FloatPoolMilestoneStatus.draft
        )
    }
}
