import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory audit is in its life cycle.
    enum InventoryAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A inventory audit. Its code is unique within a tenant.
    final class InventoryAudit {
        var code: String
        var label: String
        var timezone: String
        var limit: Int
        var budget: Double
        var version: Int
        var ward: String
        var threshold: Double
        var status: InventoryAuditStatus

        init(code: String, label: String, timezone: String, limit: Int, budget: Double, version: Int, ward: String, threshold: Double, status: InventoryAuditStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.limit = limit
            self.budget = budget
            self.version = version
            self.ward = ward
            self.threshold = threshold
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

        func canMoveTo(_ next: InventoryAuditStatus) -> Bool {
            switch status {
            case .requested:
                return next == InventoryAuditStatus.revoked || next == InventoryAuditStatus.expired
            case .granted:
                return next == InventoryAuditStatus.revoked || next == InventoryAuditStatus.expired
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

        func moveTo(_ next: InventoryAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedVolume() -> Double {
            return (Double(version) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> InventoryAudit {
            return InventoryAudit(
                code: code,
                label: label,
                timezone: timezone,
                limit: limit,
                budget: budget,
                version: version,
                ward: ward,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a inventory audit in status requested.
    static func newInventoryAudit(_ code: String, label: String) -> InventoryAudit {
        return InventoryAudit(
            code: code,
            label: label,
            timezone: "",
            limit: 0,
            budget: 0.0,
            version: 0,
            ward: "",
            threshold: 0.0,
            status: InventoryAuditStatus.requested
        )
    }
}
