import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert override is in its life cycle.
    enum AlertOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A alert override. Its code is unique within a tenant.
    final class AlertOverride {
        var code: String
        var title: String
        var unit: String
        var reviewer: String
        var capacity: Int
        var active: Bool
        var attempts: Int
        var quantity: Int
        var status: AlertOverrideStatus

        init(code: String, title: String, unit: String, reviewer: String, capacity: Int, active: Bool, attempts: Int, quantity: Int, status: AlertOverrideStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.reviewer = reviewer
            self.capacity = capacity
            self.active = active
            self.attempts = attempts
            self.quantity = quantity
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

        func canMoveTo(_ next: AlertOverrideStatus) -> Bool {
            switch status {
            case .requested:
                return next == AlertOverrideStatus.granted
            case .granted:
                switch next {
                case .revoked, .expired:
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

        func moveTo(_ next: AlertOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveLoad() -> Double {
            return ((Double(quantity) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> AlertOverride {
            return AlertOverride(
                code: code,
                title: title,
                unit: unit,
                reviewer: reviewer,
                capacity: capacity,
                active: active,
                attempts: attempts,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a alert override in status requested.
    static func newAlertOverride(_ code: String, title: String) -> AlertOverride {
        return AlertOverride(
            code: code,
            title: title,
            unit: "",
            reviewer: "",
            capacity: 0,
            active: false,
            attempts: 0,
            quantity: 0,
            status: AlertOverrideStatus.requested
        )
    }
}
