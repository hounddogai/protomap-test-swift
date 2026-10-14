import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default network rule is in its life cycle.
    enum DefaultNetworkRuleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a default network rule and its current status.
    final class DefaultNetworkRule {
        var code: String
        var label: String
        var sequence: Int
        var patientRef: String
        var durationMinutes: Int
        var country: String
        var score: Double
        var timezone: String
        var status: DefaultNetworkRuleStatus

        init(code: String, label: String, sequence: Int, patientRef: String, durationMinutes: Int, country: String, score: Double, timezone: String, status: DefaultNetworkRuleStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.patientRef = patientRef
            self.durationMinutes = durationMinutes
            self.country = country
            self.score = score
            self.timezone = timezone
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

        func canMoveTo(_ next: DefaultNetworkRuleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultNetworkRuleStatus.approved || next == DefaultNetworkRuleStatus.withdrawn
            case .approved:
                return next == DefaultNetworkRuleStatus.rejected || next == DefaultNetworkRuleStatus.withdrawn
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

        func moveTo(_ next: DefaultNetworkRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default network rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("default network rule") \(code)"
        }

        func netLoad() -> Double {
            return (score * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> DefaultNetworkRule {
            return DefaultNetworkRule(
                code: code,
                label: label,
                sequence: sequence,
                patientRef: patientRef,
                durationMinutes: durationMinutes,
                country: country,
                score: score,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a default network rule in status proposed.
    static func newDefaultNetworkRule(_ code: String, label: String) -> DefaultNetworkRule {
        return DefaultNetworkRule(
            code: code,
            label: label,
            sequence: 0,
            patientRef: "",
            durationMinutes: 0,
            country: "",
            score: 0.0,
            timezone: "",
            status: DefaultNetworkRuleStatus.proposed
        )
    }
}
