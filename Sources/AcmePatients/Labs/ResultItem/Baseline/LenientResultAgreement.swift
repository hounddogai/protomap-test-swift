import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient result agreement is in its life cycle.
    enum LenientResultAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A lenient result agreement as the result team keeps it.
    final class LenientResultAgreement {
        var code: String
        var title: String
        var createdAt: Int
        var diagnosisCode: String
        var sequence: Int
        var contactEmail: String
        var notes: String
        var reviewer: String
        var status: LenientResultAgreementStatus

        init(code: String, title: String, createdAt: Int, diagnosisCode: String, sequence: Int, contactEmail: String, notes: String, reviewer: String, status: LenientResultAgreementStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.diagnosisCode = diagnosisCode
            self.sequence = sequence
            self.contactEmail = contactEmail
            self.notes = notes
            self.reviewer = reviewer
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

        func canMoveTo(_ next: LenientResultAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LenientResultAgreementStatus.approved
            case .approved:
                return next == LenientResultAgreementStatus.rejected || next == LenientResultAgreementStatus.withdrawn
            case .rejected:
                return next == LenientResultAgreementStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientResultAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient result agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netExposure() -> Double {
            return ((Double(createdAt) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> LenientResultAgreement {
            return LenientResultAgreement(
                code: code,
                title: title,
                createdAt: createdAt,
                diagnosisCode: diagnosisCode,
                sequence: sequence,
                contactEmail: contactEmail,
                notes: notes,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient result agreement in status proposed.
    static func newLenientResultAgreement(_ code: String, title: String) -> LenientResultAgreement {
        return LenientResultAgreement(
            code: code,
            title: title,
            createdAt: 0,
            diagnosisCode: "",
            sequence: 0,
            contactEmail: "",
            notes: "",
            reviewer: "",
            status: LenientResultAgreementStatus.proposed
        )
    }
}
