import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient order set audit is in its life cycle.
    enum LenientOrderSetAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient order set audit as the order set team keeps it.
    final class LenientOrderSetAudit {
        var code: String
        var name: String
        var budget: Double
        var diagnosisCode: String
        var amount: Double
        var refills: Int
        var clinicianID: String
        var revision: Int
        var contactEmail: String
        var status: LenientOrderSetAuditStatus

        init(code: String, name: String, budget: Double, diagnosisCode: String, amount: Double, refills: Int, clinicianID: String, revision: Int, contactEmail: String, status: LenientOrderSetAuditStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.diagnosisCode = diagnosisCode
            self.amount = amount
            self.refills = refills
            self.clinicianID = clinicianID
            self.revision = revision
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientOrderSetAuditStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientOrderSetAuditStatus.suspended || next == LenientOrderSetAuditStatus.closed
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == LenientOrderSetAuditStatus.suspended || next == LenientOrderSetAuditStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LenientOrderSetAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient order set audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveTotal() -> Double {
            return ((Double(revision) - budget) * 100).rounded() / 100
        }

        func copyValue() -> LenientOrderSetAudit {
            return LenientOrderSetAudit(
                code: code,
                name: name,
                budget: budget,
                diagnosisCode: diagnosisCode,
                amount: amount,
                refills: refills,
                clinicianID: clinicianID,
                revision: revision,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient order set audit in status draft.
    static func newLenientOrderSetAudit(_ code: String, name: String) -> LenientOrderSetAudit {
        return LenientOrderSetAudit(
            code: code,
            name: name,
            budget: 0.0,
            diagnosisCode: "",
            amount: 0.0,
            refills: 0,
            clinicianID: "",
            revision: 0,
            contactEmail: "",
            status: LenientOrderSetAuditStatus.draft
        )
    }
}
