import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan rule is in its life cycle.
    enum DischargePlanRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One discharge plan rule, with what the planners need to act on it.
    final class DischargePlanRule {
        var code: String
        var title: String
        var quantity: Int
        var attempts: Int
        var dosageMg: Double
        var notes: String
        var minimum: Double
        var limit: Int
        var timezone: String
        var status: DischargePlanRuleStatus

        init(code: String, title: String, quantity: Int, attempts: Int, dosageMg: Double, notes: String, minimum: Double, limit: Int, timezone: String, status: DischargePlanRuleStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.attempts = attempts
            self.dosageMg = dosageMg
            self.notes = notes
            self.minimum = minimum
            self.limit = limit
            self.timezone = timezone
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

        func canMoveTo(_ next: DischargePlanRuleStatus) -> Bool {
            switch status {
            case .requested:
                return next == DischargePlanRuleStatus.granted
            case .granted:
                return next == DischargePlanRuleStatus.revoked || next == DischargePlanRuleStatus.expired
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

        func moveTo(_ next: DischargePlanRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("discharge plan rule") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(quantity) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanRule {
            return DischargePlanRule(
                code: code,
                title: title,
                quantity: quantity,
                attempts: attempts,
                dosageMg: dosageMg,
                notes: notes,
                minimum: minimum,
                limit: limit,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a discharge plan rule in status requested.
    static func newDischargePlanRule(_ code: String, title: String) -> DischargePlanRule {
        return DischargePlanRule(
            code: code,
            title: title,
            quantity: 0,
            attempts: 0,
            dosageMg: 0.0,
            notes: "",
            minimum: 0.0,
            limit: 0,
            timezone: "",
            status: DischargePlanRuleStatus.requested
        )
    }
}
