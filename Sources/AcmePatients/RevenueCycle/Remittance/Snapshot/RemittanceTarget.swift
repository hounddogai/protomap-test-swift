import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance target is in its life cycle.
    enum RemittanceTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A remittance target as the remittance team keeps it.
    final class RemittanceTarget {
        var code: String
        var label: String
        var capacity: Int
        var margin: Double
        var priority: Int
        var score: Double
        var timezone: String
        var active: Bool
        var status: RemittanceTargetStatus

        init(code: String, label: String, capacity: Int, margin: Double, priority: Int, score: Double, timezone: String, active: Bool, status: RemittanceTargetStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.margin = margin
            self.priority = priority
            self.score = score
            self.timezone = timezone
            self.active = active
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

        func canMoveTo(_ next: RemittanceTargetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RemittanceTargetStatus.expired
            case .revoked:
                return next == RemittanceTargetStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedTotal() -> Double {
            return ((Double(capacity) - score) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceTarget {
            return RemittanceTarget(
                code: code,
                label: label,
                capacity: capacity,
                margin: margin,
                priority: priority,
                score: score,
                timezone: timezone,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a remittance target in status requested.
    static func newRemittanceTarget(_ code: String, label: String) -> RemittanceTarget {
        return RemittanceTarget(
            code: code,
            label: label,
            capacity: 0,
            margin: 0.0,
            priority: 0,
            score: 0.0,
            timezone: "",
            active: false,
            status: RemittanceTargetStatus.requested
        )
    }
}
