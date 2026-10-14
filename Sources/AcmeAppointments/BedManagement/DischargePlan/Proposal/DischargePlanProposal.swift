import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan proposal is in its life cycle.
    enum DischargePlanProposalStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A discharge plan proposal as the discharge plan team keeps it.
    final class DischargePlanProposal {
        var code: String
        var label: String
        var capacity: Int
        var cost: Double
        var version: Int
        var archived: Bool
        var allergy: String
        var status: DischargePlanProposalStatus

        init(code: String, label: String, capacity: Int, cost: Double, version: Int, archived: Bool, allergy: String, status: DischargePlanProposalStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.cost = cost
            self.version = version
            self.archived = archived
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

        func canMoveTo(_ next: DischargePlanProposalStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == DischargePlanProposalStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return (cost * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanProposal {
            return DischargePlanProposal(
                code: code,
                label: label,
                capacity: capacity,
                cost: cost,
                version: version,
                archived: archived,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a discharge plan proposal in status draft.
    static func newDischargePlanProposal(_ code: String, label: String) -> DischargePlanProposal {
        return DischargePlanProposal(
            code: code,
            label: label,
            capacity: 0,
            cost: 0.0,
            version: 0,
            archived: false,
            allergy: "",
            status: DischargePlanProposalStatus.draft
        )
    }
}
