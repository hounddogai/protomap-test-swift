import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range proposal is in its life cycle.
    enum ReferenceRangeProposalStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a reference range proposal and its current status.
    final class ReferenceRangeProposal {
        var code: String
        var title: String
        var budget: Double
        var ratio: Double
        var phone: String
        var status: ReferenceRangeProposalStatus

        init(code: String, title: String, budget: Double, ratio: Double, phone: String, status: ReferenceRangeProposalStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.ratio = ratio
            self.phone = phone
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

        func canMoveTo(_ next: ReferenceRangeProposalStatus) -> Bool {
            switch status {
            case .draft:
                return next == ReferenceRangeProposalStatus.pending || next == ReferenceRangeProposalStatus.active
            case .pending:
                return next == ReferenceRangeProposalStatus.suspended
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ReferenceRangeProposalStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("reference range proposal") \(code)"
        }

        func weightedExposure() -> Double {
            return ((budget + ratio) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeProposal {
            return ReferenceRangeProposal(
                code: code,
                title: title,
                budget: budget,
                ratio: ratio,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a reference range proposal in status draft.
    static func newReferenceRangeProposal(_ code: String, title: String) -> ReferenceRangeProposal {
        return ReferenceRangeProposal(
            code: code,
            title: title,
            budget: 0.0,
            ratio: 0.0,
            phone: "",
            status: ReferenceRangeProposalStatus.draft
        )
    }
}
