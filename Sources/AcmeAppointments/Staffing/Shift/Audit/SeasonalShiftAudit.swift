import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal shift audit is in its life cycle.
    enum SeasonalShiftAuditStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a seasonal shift audit and its current status.
    final class SeasonalShiftAudit {
        var code: String
        var label: String
        var summary: String
        var graceDays: Int
        var capacity: Int
        var status: SeasonalShiftAuditStatus

        init(code: String, label: String, summary: String, graceDays: Int, capacity: Int, status: SeasonalShiftAuditStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.graceDays = graceDays
            self.capacity = capacity
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

        func canMoveTo(_ next: SeasonalShiftAuditStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == SeasonalShiftAuditStatus.archived
            case .reopened:
                return next == SeasonalShiftAuditStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalShiftAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal shift audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("seasonal shift audit") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(graceDays) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalShiftAudit {
            return SeasonalShiftAudit(
                code: code,
                label: label,
                summary: summary,
                graceDays: graceDays,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal shift audit in status open.
    static func newSeasonalShiftAudit(_ code: String, label: String) -> SeasonalShiftAudit {
        return SeasonalShiftAudit(
            code: code,
            label: label,
            summary: "",
            graceDays: 0,
            capacity: 0,
            status: SeasonalShiftAuditStatus.`open`
        )
    }
}
