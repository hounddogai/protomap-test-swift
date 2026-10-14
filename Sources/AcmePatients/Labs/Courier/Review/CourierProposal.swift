import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier proposal is in its life cycle.
    enum CourierProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A courier proposal. Its code is unique within a tenant.
    final class CourierProposal {
        var code: String
        var name: String
        var durationMinutes: Int
        var pinned: Bool
        var revision: Int
        var procedureCode: String
        var patientRef: String
        var batchSize: Int
        var status: CourierProposalStatus

        init(code: String, name: String, durationMinutes: Int, pinned: Bool, revision: Int, procedureCode: String, patientRef: String, batchSize: Int, status: CourierProposalStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.pinned = pinned
            self.revision = revision
            self.procedureCode = procedureCode
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CourierProposalStatus.reopened
            case .inReview:
                return next == CourierProposalStatus.reopened
            case .resolved:
                return next == CourierProposalStatus.reopened
            case .reopened:
                return next == CourierProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("courier proposal") \(code)"
        }

        func netValue() -> Double {
            return ((Double(batchSize) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CourierProposal {
            return CourierProposal(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                pinned: pinned,
                revision: revision,
                procedureCode: procedureCode,
                patientRef: patientRef,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a courier proposal in status open.
    static func newCourierProposal(_ code: String, name: String) -> CourierProposal {
        return CourierProposal(
            code: code,
            name: name,
            durationMinutes: 0,
            pinned: false,
            revision: 0,
            procedureCode: "",
            patientRef: "",
            batchSize: 0,
            status: CourierProposalStatus.`open`
        )
    }
}
