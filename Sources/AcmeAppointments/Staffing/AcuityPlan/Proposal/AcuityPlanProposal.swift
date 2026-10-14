import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan proposal is in its life cycle.
    enum AcuityPlanProposalStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One acuity plan proposal, with what the planners need to act on it.
    final class AcuityPlanProposal {
        var code: String
        var title: String
        var checksum: String
        var startsAt: Int
        var allergy: String
        var status: AcuityPlanProposalStatus

        init(code: String, title: String, checksum: String, startsAt: Int, allergy: String, status: AcuityPlanProposalStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.startsAt = startsAt
            self.allergy = allergy
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

        func canMoveTo(_ next: AcuityPlanProposalStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == AcuityPlanProposalStatus.suspended || next == AcuityPlanProposalStatus.closed
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

        func moveTo(_ next: AcuityPlanProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("acuity plan proposal") \(code)"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> AcuityPlanProposal {
            return AcuityPlanProposal(
                code: code,
                title: title,
                checksum: checksum,
                startsAt: startsAt,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a acuity plan proposal in status draft.
    static func newAcuityPlanProposal(_ code: String, title: String) -> AcuityPlanProposal {
        return AcuityPlanProposal(
            code: code,
            title: title,
            checksum: "",
            startsAt: 0,
            allergy: "",
            status: AcuityPlanProposalStatus.draft
        )
    }
}
