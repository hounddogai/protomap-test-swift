import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled risk score audit is in its life cycle.
    enum ScheduledRiskScoreAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A scheduled risk score audit as the risk score team keeps it.
    final class ScheduledRiskScoreAudit {
        var code: String
        var title: String
        var ownerID: String
        var dosageMg: Double
        var patientRef: String
        var endsAt: Int
        var sequence: Int
        var attempts: Int
        var payer: String
        var status: ScheduledRiskScoreAuditStatus

        init(code: String, title: String, ownerID: String, dosageMg: Double, patientRef: String, endsAt: Int, sequence: Int, attempts: Int, payer: String, status: ScheduledRiskScoreAuditStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.dosageMg = dosageMg
            self.patientRef = patientRef
            self.endsAt = endsAt
            self.sequence = sequence
            self.attempts = attempts
            self.payer = payer
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

        func canMoveTo(_ next: ScheduledRiskScoreAuditStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledRiskScoreAuditStatus.validated || next == ScheduledRiskScoreAuditStatus.published
            case .validated:
                return next == ScheduledRiskScoreAuditStatus.retired
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

        func moveTo(_ next: ScheduledRiskScoreAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled risk score audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("scheduled risk score audit") \(code)"
        }

        func projectedValue() -> Double {
            return (Double(attempts) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledRiskScoreAudit {
            return ScheduledRiskScoreAudit(
                code: code,
                title: title,
                ownerID: ownerID,
                dosageMg: dosageMg,
                patientRef: patientRef,
                endsAt: endsAt,
                sequence: sequence,
                attempts: attempts,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled risk score audit in status created.
    static func newScheduledRiskScoreAudit(_ code: String, title: String) -> ScheduledRiskScoreAudit {
        return ScheduledRiskScoreAudit(
            code: code,
            title: title,
            ownerID: "",
            dosageMg: 0.0,
            patientRef: "",
            endsAt: 0,
            sequence: 0,
            attempts: 0,
            payer: "",
            status: ScheduledRiskScoreAuditStatus.created
        )
    }
}
