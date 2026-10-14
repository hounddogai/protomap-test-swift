import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution proposal is in its life cycle.
    enum SubstitutionProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One substitution proposal, with what the planners need to act on it.
    final class SubstitutionProposal {
        var code: String
        var title: String
        var copay: Double
        var procedureCode: String
        var acuity: Int
        var status: SubstitutionProposalStatus

        init(code: String, title: String, copay: Double, procedureCode: String, acuity: Int, status: SubstitutionProposalStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.procedureCode = procedureCode
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SubstitutionProposalStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == SubstitutionProposalStatus.done || next == SubstitutionProposalStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: SubstitutionProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("substitution proposal") \(code)"
        }

        func adjustedTotal() -> Double {
            return (Double(acuity) * copay * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionProposal {
            return SubstitutionProposal(
                code: code,
                title: title,
                copay: copay,
                procedureCode: procedureCode,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a substitution proposal in status new.
    static func newSubstitutionProposal(_ code: String, title: String) -> SubstitutionProposal {
        return SubstitutionProposal(
            code: code,
            title: title,
            copay: 0.0,
            procedureCode: "",
            acuity: 0,
            status: SubstitutionProposalStatus.new
        )
    }
}
