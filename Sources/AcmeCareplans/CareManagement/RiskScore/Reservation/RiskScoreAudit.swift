import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score audit is in its life cycle.
    enum RiskScoreAuditStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A risk score audit as the risk score team keeps it.
    final class RiskScoreAudit {
        var code: String
        var title: String
        var windowDays: Int
        var label: String
        var amount: Double
        var status: RiskScoreAuditStatus

        init(code: String, title: String, windowDays: Int, label: String, amount: Double, status: RiskScoreAuditStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.label = label
            self.amount = amount
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

        func canMoveTo(_ next: RiskScoreAuditStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RiskScoreAuditStatus.ready || next == RiskScoreAuditStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RiskScoreAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("risk score audit") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(windowDays) * amount * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreAudit {
            return RiskScoreAudit(
                code: code,
                title: title,
                windowDays: windowDays,
                label: label,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a risk score audit in status idle.
    static func newRiskScoreAudit(_ code: String, title: String) -> RiskScoreAudit {
        return RiskScoreAudit(
            code: code,
            title: title,
            windowDays: 0,
            label: "",
            amount: 0.0,
            status: RiskScoreAuditStatus.idle
        )
    }
}
