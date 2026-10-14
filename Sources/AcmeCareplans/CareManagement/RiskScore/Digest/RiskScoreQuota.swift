import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score quota is in its life cycle.
    enum RiskScoreQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A risk score quota as the risk score team keeps it.
    final class RiskScoreQuota {
        var code: String
        var label: String
        var score: Double
        var approved: Bool
        var patientRef: String
        var visible: Bool
        var discount: Double
        var status: RiskScoreQuotaStatus

        init(code: String, label: String, score: Double, approved: Bool, patientRef: String, visible: Bool, discount: Double, status: RiskScoreQuotaStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.approved = approved
            self.patientRef = patientRef
            self.visible = visible
            self.discount = discount
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

        func canMoveTo(_ next: RiskScoreQuotaStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RiskScoreQuotaStatus.published || next == RiskScoreQuotaStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RiskScoreQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedValue() -> Double {
            return ((score - discount) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreQuota {
            return RiskScoreQuota(
                code: code,
                label: label,
                score: score,
                approved: approved,
                patientRef: patientRef,
                visible: visible,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a risk score quota in status created.
    static func newRiskScoreQuota(_ code: String, label: String) -> RiskScoreQuota {
        return RiskScoreQuota(
            code: code,
            label: label,
            score: 0.0,
            approved: false,
            patientRef: "",
            visible: false,
            discount: 0.0,
            status: RiskScoreQuotaStatus.created
        )
    }
}
