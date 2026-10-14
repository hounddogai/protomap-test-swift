import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment audit is in its life cycle.
    enum AssessmentAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One assessment audit, with what the planners need to act on it.
    final class AssessmentAudit {
        var code: String
        var name: String
        var source: String
        var currency: String
        var endsAt: Int
        var patientRef: String
        var copay: Double
        var sequence: Int
        var status: AssessmentAuditStatus

        init(code: String, name: String, source: String, currency: String, endsAt: Int, patientRef: String, copay: Double, sequence: Int, status: AssessmentAuditStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.currency = currency
            self.endsAt = endsAt
            self.patientRef = patientRef
            self.copay = copay
            self.sequence = sequence
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

        func canMoveTo(_ next: AssessmentAuditStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AssessmentAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("assessment audit") \(code)"
        }

        func projectedExposure() -> Double {
            return (Double(sequence) * copay * 100).rounded() / 100
        }

        func copyValue() -> AssessmentAudit {
            return AssessmentAudit(
                code: code,
                name: name,
                source: source,
                currency: currency,
                endsAt: endsAt,
                patientRef: patientRef,
                copay: copay,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a assessment audit in status created.
    static func newAssessmentAudit(_ code: String, name: String) -> AssessmentAudit {
        return AssessmentAudit(
            code: code,
            name: name,
            source: "",
            currency: "",
            endsAt: 0,
            patientRef: "",
            copay: 0.0,
            sequence: 0,
            status: AssessmentAuditStatus.created
        )
    }
}
