import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score preference is in its life cycle.
    enum RiskScorePreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a risk score preference and its current status.
    final class RiskScorePreference {
        var code: String
        var name: String
        var ceiling: Double
        var timezone: String
        var acuity: Int
        var cost: Double
        var label: String
        var updatedAt: Int
        var status: RiskScorePreferenceStatus

        init(code: String, name: String, ceiling: Double, timezone: String, acuity: Int, cost: Double, label: String, updatedAt: Int, status: RiskScorePreferenceStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.timezone = timezone
            self.acuity = acuity
            self.cost = cost
            self.label = label
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: RiskScorePreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RiskScorePreferenceStatus.rejected || next == RiskScorePreferenceStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == RiskScorePreferenceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScorePreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func netVolume() -> Double {
            return (ceiling * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> RiskScorePreference {
            return RiskScorePreference(
                code: code,
                name: name,
                ceiling: ceiling,
                timezone: timezone,
                acuity: acuity,
                cost: cost,
                label: label,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a risk score preference in status proposed.
    static func newRiskScorePreference(_ code: String, name: String) -> RiskScorePreference {
        return RiskScorePreference(
            code: code,
            name: name,
            ceiling: 0.0,
            timezone: "",
            acuity: 0,
            cost: 0.0,
            label: "",
            updatedAt: 0,
            status: RiskScorePreferenceStatus.proposed
        )
    }
}
