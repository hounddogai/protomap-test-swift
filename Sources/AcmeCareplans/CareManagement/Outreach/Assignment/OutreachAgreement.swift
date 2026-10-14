import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach agreement is in its life cycle.
    enum OutreachAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A outreach agreement. Its code is unique within a tenant.
    final class OutreachAgreement {
        var code: String
        var title: String
        var label: String
        var specialty: String
        var sequence: Int
        var ownerID: String
        var clinicianID: String
        var budget: Double
        var expiresAt: Int
        var bed: String
        var status: OutreachAgreementStatus

        init(code: String, title: String, label: String, specialty: String, sequence: Int, ownerID: String, clinicianID: String, budget: Double, expiresAt: Int, bed: String, status: OutreachAgreementStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.specialty = specialty
            self.sequence = sequence
            self.ownerID = ownerID
            self.clinicianID = clinicianID
            self.budget = budget
            self.expiresAt = expiresAt
            self.bed = bed
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

        func canMoveTo(_ next: OutreachAgreementStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == OutreachAgreementStatus.suspended || next == OutreachAgreementStatus.closed
            case .active:
                return next == OutreachAgreementStatus.suspended || next == OutreachAgreementStatus.closed
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

        func moveTo(_ next: OutreachAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func netExposure() -> Double {
            return (Double(sequence) * budget * 100).rounded() / 100
        }

        func copyValue() -> OutreachAgreement {
            return OutreachAgreement(
                code: code,
                title: title,
                label: label,
                specialty: specialty,
                sequence: sequence,
                ownerID: ownerID,
                clinicianID: clinicianID,
                budget: budget,
                expiresAt: expiresAt,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a outreach agreement in status draft.
    static func newOutreachAgreement(_ code: String, title: String) -> OutreachAgreement {
        return OutreachAgreement(
            code: code,
            title: title,
            label: "",
            specialty: "",
            sequence: 0,
            ownerID: "",
            clinicianID: "",
            budget: 0.0,
            expiresAt: 0,
            bed: "",
            status: OutreachAgreementStatus.draft
        )
    }
}
