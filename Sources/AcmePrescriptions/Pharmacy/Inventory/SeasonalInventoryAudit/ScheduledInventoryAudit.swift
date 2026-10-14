import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a scheduled inventory audit is in its life cycle.
    enum ScheduledInventoryAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A scheduled inventory audit as the inventory team keeps it.
    final class ScheduledInventoryAudit {
        var code: String
        var title: String
        var visitMinutes: Int
        var acuity: Int
        var minimum: Double
        var updatedAt: Int
        var segment: String
        var status: ScheduledInventoryAuditStatus

        init(code: String, title: String, visitMinutes: Int, acuity: Int, minimum: Double, updatedAt: Int, segment: String, status: ScheduledInventoryAuditStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.acuity = acuity
            self.minimum = minimum
            self.updatedAt = updatedAt
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledInventoryAuditStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ScheduledInventoryAuditStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledInventoryAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled inventory audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netExposure() -> Double {
            return (Double(updatedAt) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledInventoryAudit {
            return ScheduledInventoryAudit(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                acuity: acuity,
                minimum: minimum,
                updatedAt: updatedAt,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled inventory audit in status created.
    static func newScheduledInventoryAudit(_ code: String, title: String) -> ScheduledInventoryAudit {
        return ScheduledInventoryAudit(
            code: code,
            title: title,
            visitMinutes: 0,
            acuity: 0,
            minimum: 0.0,
            updatedAt: 0,
            segment: "",
            status: ScheduledInventoryAuditStatus.created
        )
    }
}
