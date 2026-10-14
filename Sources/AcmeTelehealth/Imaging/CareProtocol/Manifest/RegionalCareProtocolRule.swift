import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional care protocol rule is in its life cycle.
    enum RegionalCareProtocolRuleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional care protocol rule as the care protocol team keeps it.
    final class RegionalCareProtocolRule {
        var code: String
        var label: String
        var attributes: [String: String]
        var priority: Int
        var ceiling: Double
        var amount: Double
        var status: RegionalCareProtocolRuleStatus

        init(code: String, label: String, attributes: [String: String], priority: Int, ceiling: Double, amount: Double, status: RegionalCareProtocolRuleStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.priority = priority
            self.ceiling = ceiling
            self.amount = amount
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

        func canMoveTo(_ next: RegionalCareProtocolRuleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RegionalCareProtocolRuleStatus.published || next == RegionalCareProtocolRuleStatus.retired
            case .published:
                return next == RegionalCareProtocolRuleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalCareProtocolRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional care protocol rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("regional care protocol rule") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedVolume() -> Double {
            return ((ceiling - amount) * 100).rounded() / 100
        }

        func copyValue() -> RegionalCareProtocolRule {
            return RegionalCareProtocolRule(
                code: code,
                label: label,
                attributes: attributes,
                priority: priority,
                ceiling: ceiling,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional care protocol rule in status created.
    static func newRegionalCareProtocolRule(_ code: String, label: String) -> RegionalCareProtocolRule {
        return RegionalCareProtocolRule(
            code: code,
            label: label,
            attributes: [:],
            priority: 0,
            ceiling: 0.0,
            amount: 0.0,
            status: RegionalCareProtocolRuleStatus.created
        )
    }
}
