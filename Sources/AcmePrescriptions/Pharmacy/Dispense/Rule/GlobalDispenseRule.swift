import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global dispense rule is in its life cycle.
    enum GlobalDispenseRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A global dispense rule as the dispense team keeps it.
    final class GlobalDispenseRule {
        var code: String
        var label: String
        var createdAt: Int
        var region: String
        var active: Bool
        var diagnosisCode: String
        var status: GlobalDispenseRuleStatus

        init(code: String, label: String, createdAt: Int, region: String, active: Bool, diagnosisCode: String, status: GlobalDispenseRuleStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.region = region
            self.active = active
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: GlobalDispenseRuleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
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

        func moveTo(_ next: GlobalDispenseRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global dispense rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> GlobalDispenseRule {
            return GlobalDispenseRule(
                code: code,
                label: label,
                createdAt: createdAt,
                region: region,
                active: active,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global dispense rule in status requested.
    static func newGlobalDispenseRule(_ code: String, label: String) -> GlobalDispenseRule {
        return GlobalDispenseRule(
            code: code,
            label: label,
            createdAt: 0,
            region: "",
            active: false,
            diagnosisCode: "",
            status: GlobalDispenseRuleStatus.requested
        )
    }
}
