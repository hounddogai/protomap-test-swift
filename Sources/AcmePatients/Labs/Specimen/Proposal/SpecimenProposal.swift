import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen proposal is in its life cycle.
    enum SpecimenProposalStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a specimen proposal and its current status.
    final class SpecimenProposal {
        var code: String
        var title: String
        var phone: String
        var ownerID: String
        var ceiling: Double
        var clinicianID: String
        var status: SpecimenProposalStatus

        init(code: String, title: String, phone: String, ownerID: String, ceiling: Double, clinicianID: String, status: SpecimenProposalStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.ownerID = ownerID
            self.ceiling = ceiling
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: SpecimenProposalStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SpecimenProposalStatus.active
            case .active:
                return next == SpecimenProposalStatus.suspended || next == SpecimenProposalStatus.closed
            case .suspended:
                return next == SpecimenProposalStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> SpecimenProposal {
            return SpecimenProposal(
                code: code,
                title: title,
                phone: phone,
                ownerID: ownerID,
                ceiling: ceiling,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a specimen proposal in status draft.
    static func newSpecimenProposal(_ code: String, title: String) -> SpecimenProposal {
        return SpecimenProposal(
            code: code,
            title: title,
            phone: "",
            ownerID: "",
            ceiling: 0.0,
            clinicianID: "",
            status: SpecimenProposalStatus.draft
        )
    }
}
