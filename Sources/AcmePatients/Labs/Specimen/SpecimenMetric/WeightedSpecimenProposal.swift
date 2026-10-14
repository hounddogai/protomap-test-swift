import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted specimen proposal is in its life cycle.
    enum WeightedSpecimenProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a weighted specimen proposal and its current status.
    final class WeightedSpecimenProposal {
        var code: String
        var title: String
        var facility: String
        var name: String
        var startsAt: Int
        var status: WeightedSpecimenProposalStatus

        init(code: String, title: String, facility: String, name: String, startsAt: Int, status: WeightedSpecimenProposalStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.name = name
            self.startsAt = startsAt
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

        func canMoveTo(_ next: WeightedSpecimenProposalStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == WeightedSpecimenProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedSpecimenProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted specimen proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> WeightedSpecimenProposal {
            return WeightedSpecimenProposal(
                code: code,
                title: title,
                facility: facility,
                name: name,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted specimen proposal in status open.
    static func newWeightedSpecimenProposal(_ code: String, title: String) -> WeightedSpecimenProposal {
        return WeightedSpecimenProposal(
            code: code,
            title: title,
            facility: "",
            name: "",
            startsAt: 0,
            status: WeightedSpecimenProposalStatus.`open`
        )
    }
}
