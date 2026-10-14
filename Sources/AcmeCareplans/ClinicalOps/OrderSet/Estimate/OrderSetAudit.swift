import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set audit is in its life cycle.
    enum OrderSetAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a order set audit and its current status.
    final class OrderSetAudit {
        var code: String
        var name: String
        var summary: String
        var specialty: String
        var cost: Double
        var status: OrderSetAuditStatus

        init(code: String, name: String, summary: String, specialty: String, cost: Double, status: OrderSetAuditStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.specialty = specialty
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OrderSetAuditStatus) -> Bool {
            switch status {
            case .requested:
                return next == OrderSetAuditStatus.revoked || next == OrderSetAuditStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: OrderSetAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> OrderSetAudit {
            return OrderSetAudit(
                code: code,
                name: name,
                summary: summary,
                specialty: specialty,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a order set audit in status requested.
    static func newOrderSetAudit(_ code: String, name: String) -> OrderSetAudit {
        return OrderSetAudit(
            code: code,
            name: name,
            summary: "",
            specialty: "",
            cost: 0.0,
            status: OrderSetAuditStatus.requested
        )
    }
}
