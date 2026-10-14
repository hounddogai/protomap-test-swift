import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal audit is in its life cycle.
    enum GoalAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A goal audit. Its code is unique within a tenant.
    final class GoalAudit {
        var code: String
        var label: String
        var expiresAt: Int
        var rate: Double
        var sequence: Int
        var dosageMg: Double
        var diagnosisCode: String
        var budget: Double
        var status: GoalAuditStatus

        init(code: String, label: String, expiresAt: Int, rate: Double, sequence: Int, dosageMg: Double, diagnosisCode: String, budget: Double, status: GoalAuditStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.rate = rate
            self.sequence = sequence
            self.dosageMg = dosageMg
            self.diagnosisCode = diagnosisCode
            self.budget = budget
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

        func canMoveTo(_ next: GoalAuditStatus) -> Bool {
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
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == GoalAuditStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedVolume() -> Double {
            return (Double(expiresAt) * rate * 100).rounded() / 100
        }

        func copyValue() -> GoalAudit {
            return GoalAudit(
                code: code,
                label: label,
                expiresAt: expiresAt,
                rate: rate,
                sequence: sequence,
                dosageMg: dosageMg,
                diagnosisCode: diagnosisCode,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a goal audit in status requested.
    static func newGoalAudit(_ code: String, label: String) -> GoalAudit {
        return GoalAudit(
            code: code,
            label: label,
            expiresAt: 0,
            rate: 0.0,
            sequence: 0,
            dosageMg: 0.0,
            diagnosisCode: "",
            budget: 0.0,
            status: GoalAuditStatus.requested
        )
    }
}
