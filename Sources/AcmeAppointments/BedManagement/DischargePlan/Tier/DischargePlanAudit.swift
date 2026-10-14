import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan audit is in its life cycle.
    enum DischargePlanAuditStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A discharge plan audit as the discharge plan team keeps it.
    final class DischargePlanAudit {
        var code: String
        var title: String
        var attempts: Int
        var name: String
        var cost: Double
        var status: DischargePlanAuditStatus

        init(code: String, title: String, attempts: Int, name: String, cost: Double, status: DischargePlanAuditStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.name = name
            self.cost = cost
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

        func canMoveTo(_ next: DischargePlanAuditStatus) -> Bool {
            switch status {
            case .idle:
                return next == DischargePlanAuditStatus.draining
            case .warming:
                return next == DischargePlanAuditStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DischargePlanAuditStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netLoad() -> Double {
            return ((cost - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanAudit {
            return DischargePlanAudit(
                code: code,
                title: title,
                attempts: attempts,
                name: name,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a discharge plan audit in status idle.
    static func newDischargePlanAudit(_ code: String, title: String) -> DischargePlanAudit {
        return DischargePlanAudit(
            code: code,
            title: title,
            attempts: 0,
            name: "",
            cost: 0.0,
            status: DischargePlanAuditStatus.idle
        )
    }
}
