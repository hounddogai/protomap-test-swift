import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel proposal is in its life cycle.
    enum PanelProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a panel proposal and its current status.
    final class PanelProposal {
        var code: String
        var label: String
        var cost: Double
        var startsAt: Int
        var updatedAt: Int
        var status: PanelProposalStatus

        init(code: String, label: String, cost: Double, startsAt: Int, updatedAt: Int, status: PanelProposalStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.startsAt = startsAt
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: PanelProposalStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PanelProposalStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedVolume() -> Double {
            return ((Double(startsAt) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> PanelProposal {
            return PanelProposal(
                code: code,
                label: label,
                cost: cost,
                startsAt: startsAt,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a panel proposal in status proposed.
    static func newPanelProposal(_ code: String, label: String) -> PanelProposal {
        return PanelProposal(
            code: code,
            label: label,
            cost: 0.0,
            startsAt: 0,
            updatedAt: 0,
            status: PanelProposalStatus.proposed
        )
    }
}
