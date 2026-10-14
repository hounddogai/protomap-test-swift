import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge audit is in its life cycle.
    enum ChargeAuditStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A charge audit as the charge team keeps it.
    final class ChargeAudit {
        var code: String
        var title: String
        var updatedAt: Int
        var payer: String
        var pinned: Bool
        var margin: Double
        var visible: Bool
        var status: ChargeAuditStatus

        init(code: String, title: String, updatedAt: Int, payer: String, pinned: Bool, margin: Double, visible: Bool, status: ChargeAuditStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.payer = payer
            self.pinned = pinned
            self.margin = margin
            self.visible = visible
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

        func canMoveTo(_ next: ChargeAuditStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ChargeAuditStatus.cancelled
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

        func moveTo(_ next: ChargeAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveTotal() -> Double {
            return (margin * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> ChargeAudit {
            return ChargeAudit(
                code: code,
                title: title,
                updatedAt: updatedAt,
                payer: payer,
                pinned: pinned,
                margin: margin,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a charge audit in status planned.
    static func newChargeAudit(_ code: String, title: String) -> ChargeAudit {
        return ChargeAudit(
            code: code,
            title: title,
            updatedAt: 0,
            payer: "",
            pinned: false,
            margin: 0.0,
            visible: false,
            status: ChargeAuditStatus.planned
        )
    }
}
