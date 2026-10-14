import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient remittance audit is in its life cycle.
    enum LenientRemittanceAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a lenient remittance audit and its current status.
    final class LenientRemittanceAudit {
        var code: String
        var title: String
        var revision: Int
        var patientRef: String
        var name: String
        var copay: Double
        var clinicianID: String
        var timezone: String
        var limit: Int
        var status: LenientRemittanceAuditStatus

        init(code: String, title: String, revision: Int, patientRef: String, name: String, copay: Double, clinicianID: String, timezone: String, limit: Int, status: LenientRemittanceAuditStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.patientRef = patientRef
            self.name = name
            self.copay = copay
            self.clinicianID = clinicianID
            self.timezone = timezone
            self.limit = limit
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

        func canMoveTo(_ next: LenientRemittanceAuditStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == LenientRemittanceAuditStatus.retired
            case .published:
                return next == LenientRemittanceAuditStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientRemittanceAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient remittance audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("lenient remittance audit") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(limit) + copay) * 100).rounded() / 100
        }

        func copyValue() -> LenientRemittanceAudit {
            return LenientRemittanceAudit(
                code: code,
                title: title,
                revision: revision,
                patientRef: patientRef,
                name: name,
                copay: copay,
                clinicianID: clinicianID,
                timezone: timezone,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient remittance audit in status created.
    static func newLenientRemittanceAudit(_ code: String, title: String) -> LenientRemittanceAudit {
        return LenientRemittanceAudit(
            code: code,
            title: title,
            revision: 0,
            patientRef: "",
            name: "",
            copay: 0.0,
            clinicianID: "",
            timezone: "",
            limit: 0,
            status: LenientRemittanceAuditStatus.created
        )
    }
}
