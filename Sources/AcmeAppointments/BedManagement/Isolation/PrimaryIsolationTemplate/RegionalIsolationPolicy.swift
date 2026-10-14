import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a regional isolation policy is in its life cycle.
    enum RegionalIsolationPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A regional isolation policy as the isolation team keeps it.
    final class RegionalIsolationPolicy {
        var code: String
        var label: String
        var score: Double
        var facility: String
        var payer: String
        var archived: Bool
        var cost: Double
        var active: Bool
        var diagnosisCode: String
        var status: RegionalIsolationPolicyStatus

        init(code: String, label: String, score: Double, facility: String, payer: String, archived: Bool, cost: Double, active: Bool, diagnosisCode: String, status: RegionalIsolationPolicyStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.facility = facility
            self.payer = payer
            self.archived = archived
            self.cost = cost
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

        func canMoveTo(_ next: RegionalIsolationPolicyStatus) -> Bool {
            switch status {
            case .requested:
                return next == RegionalIsolationPolicyStatus.revoked
            case .granted:
                return next == RegionalIsolationPolicyStatus.revoked || next == RegionalIsolationPolicyStatus.expired
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

        func moveTo(_ next: RegionalIsolationPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional isolation policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedVolume() -> Double {
            return (score * cost * 100).rounded() / 100
        }

        func copyValue() -> RegionalIsolationPolicy {
            return RegionalIsolationPolicy(
                code: code,
                label: label,
                score: score,
                facility: facility,
                payer: payer,
                archived: archived,
                cost: cost,
                active: active,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a regional isolation policy in status requested.
    static func newRegionalIsolationPolicy(_ code: String, label: String) -> RegionalIsolationPolicy {
        return RegionalIsolationPolicy(
            code: code,
            label: label,
            score: 0.0,
            facility: "",
            payer: "",
            archived: false,
            cost: 0.0,
            active: false,
            diagnosisCode: "",
            status: RegionalIsolationPolicyStatus.requested
        )
    }
}
