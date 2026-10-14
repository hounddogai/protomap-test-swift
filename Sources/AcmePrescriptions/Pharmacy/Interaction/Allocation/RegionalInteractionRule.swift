import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional interaction rule is in its life cycle.
    enum RegionalInteractionRuleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A regional interaction rule. Its code is unique within a tenant.
    final class RegionalInteractionRule {
        var code: String
        var name: String
        var visitMinutes: Int
        var copay: Double
        var bed: String
        var updatedAt: Int
        var approved: Bool
        var capacity: Int
        var attempts: Int
        var status: RegionalInteractionRuleStatus

        init(code: String, name: String, visitMinutes: Int, copay: Double, bed: String, updatedAt: Int, approved: Bool, capacity: Int, attempts: Int, status: RegionalInteractionRuleStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.copay = copay
            self.bed = bed
            self.updatedAt = updatedAt
            self.approved = approved
            self.capacity = capacity
            self.attempts = attempts
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

        func canMoveTo(_ next: RegionalInteractionRuleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalInteractionRuleStatus.approved || next == RegionalInteractionRuleStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RegionalInteractionRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional interaction rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedTotal() -> Double {
            return ((Double(updatedAt) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalInteractionRule {
            return RegionalInteractionRule(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                copay: copay,
                bed: bed,
                updatedAt: updatedAt,
                approved: approved,
                capacity: capacity,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional interaction rule in status proposed.
    static func newRegionalInteractionRule(_ code: String, name: String) -> RegionalInteractionRule {
        return RegionalInteractionRule(
            code: code,
            name: name,
            visitMinutes: 0,
            copay: 0.0,
            bed: "",
            updatedAt: 0,
            approved: false,
            capacity: 0,
            attempts: 0,
            status: RegionalInteractionRuleStatus.proposed
        )
    }
}
