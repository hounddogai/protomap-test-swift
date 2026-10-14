import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary credential proposal is in its life cycle.
    enum PrimaryCredentialProposalStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a primary credential proposal and its current status.
    final class PrimaryCredentialProposal {
        var code: String
        var name: String
        var segment: String
        var facility: String
        var retries: Int
        var endsAt: Int
        var patientRef: String
        var notes: String
        var status: PrimaryCredentialProposalStatus

        init(code: String, name: String, segment: String, facility: String, retries: Int, endsAt: Int, patientRef: String, notes: String, status: PrimaryCredentialProposalStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.facility = facility
            self.retries = retries
            self.endsAt = endsAt
            self.patientRef = patientRef
            self.notes = notes
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

        func canMoveTo(_ next: PrimaryCredentialProposalStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryCredentialProposalStatus.pending || next == PrimaryCredentialProposalStatus.suspended
            case .pending:
                return next == PrimaryCredentialProposalStatus.suspended || next == PrimaryCredentialProposalStatus.closed
            case .active:
                return next == PrimaryCredentialProposalStatus.suspended || next == PrimaryCredentialProposalStatus.closed
            case .suspended:
                return next == PrimaryCredentialProposalStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryCredentialProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary credential proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary credential proposal") \(code)"
        }

        func projectedVolume() -> Double {
            return (Double(retries) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCredentialProposal {
            return PrimaryCredentialProposal(
                code: code,
                name: name,
                segment: segment,
                facility: facility,
                retries: retries,
                endsAt: endsAt,
                patientRef: patientRef,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a primary credential proposal in status draft.
    static func newPrimaryCredentialProposal(_ code: String, name: String) -> PrimaryCredentialProposal {
        return PrimaryCredentialProposal(
            code: code,
            name: name,
            segment: "",
            facility: "",
            retries: 0,
            endsAt: 0,
            patientRef: "",
            notes: "",
            status: PrimaryCredentialProposalStatus.draft
        )
    }
}
