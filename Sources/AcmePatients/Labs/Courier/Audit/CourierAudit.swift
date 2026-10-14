import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier audit is in its life cycle.
    enum CourierAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One courier audit, with what the planners need to act on it.
    final class CourierAudit {
        var code: String
        var title: String
        var summary: String
        var expiresAt: Int
        var ward: String
        var acuity: Int
        var maximum: Double
        var notes: String
        var cost: Double
        var status: CourierAuditStatus

        init(code: String, title: String, summary: String, expiresAt: Int, ward: String, acuity: Int, maximum: Double, notes: String, cost: Double, status: CourierAuditStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.expiresAt = expiresAt
            self.ward = ward
            self.acuity = acuity
            self.maximum = maximum
            self.notes = notes
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierAuditStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CourierAuditStatus.approved || next == CourierAuditStatus.rejected
            case .approved:
                return next == CourierAuditStatus.rejected || next == CourierAuditStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: CourierAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netTotal() -> Double {
            return (cost * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> CourierAudit {
            return CourierAudit(
                code: code,
                title: title,
                summary: summary,
                expiresAt: expiresAt,
                ward: ward,
                acuity: acuity,
                maximum: maximum,
                notes: notes,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a courier audit in status proposed.
    static func newCourierAudit(_ code: String, title: String) -> CourierAudit {
        return CourierAudit(
            code: code,
            title: title,
            summary: "",
            expiresAt: 0,
            ward: "",
            acuity: 0,
            maximum: 0.0,
            notes: "",
            cost: 0.0,
            status: CourierAuditStatus.proposed
        )
    }
}
