import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict inventory audit is in its life cycle.
    enum StrictInventoryAuditStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A strict inventory audit as the inventory team keeps it.
    final class StrictInventoryAudit {
        var code: String
        var name: String
        var score: Double
        var segment: String
        var externalRef: String
        var timezone: String
        var status: StrictInventoryAuditStatus

        init(code: String, name: String, score: Double, segment: String, externalRef: String, timezone: String, status: StrictInventoryAuditStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.segment = segment
            self.externalRef = externalRef
            self.timezone = timezone
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

        func canMoveTo(_ next: StrictInventoryAuditStatus) -> Bool {
            switch status {
            case .planned:
                return next == StrictInventoryAuditStatus.inProgress || next == StrictInventoryAuditStatus.completed
            case .scheduled:
                return next == StrictInventoryAuditStatus.inProgress
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == StrictInventoryAuditStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictInventoryAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict inventory audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict inventory audit") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> StrictInventoryAudit {
            return StrictInventoryAudit(
                code: code,
                name: name,
                score: score,
                segment: segment,
                externalRef: externalRef,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a strict inventory audit in status planned.
    static func newStrictInventoryAudit(_ code: String, name: String) -> StrictInventoryAudit {
        return StrictInventoryAudit(
            code: code,
            name: name,
            score: 0.0,
            segment: "",
            externalRef: "",
            timezone: "",
            status: StrictInventoryAuditStatus.planned
        )
    }
}
