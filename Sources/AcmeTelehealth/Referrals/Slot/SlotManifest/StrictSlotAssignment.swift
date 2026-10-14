import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict slot assignment is in its life cycle.
    enum StrictSlotAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict slot assignment as the slot team keeps it.
    final class StrictSlotAssignment {
        var code: String
        var name: String
        var cost: Double
        var patientRef: String
        var notes: String
        var tags: [String]
        var status: StrictSlotAssignmentStatus

        init(code: String, name: String, cost: Double, patientRef: String, notes: String, tags: [String], status: StrictSlotAssignmentStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.patientRef = patientRef
            self.notes = notes
            self.tags = tags
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

        func canMoveTo(_ next: StrictSlotAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == StrictSlotAssignmentStatus.suspended || next == StrictSlotAssignmentStatus.closed
            case .suspended:
                return next == StrictSlotAssignmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictSlotAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict slot assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> StrictSlotAssignment {
            return StrictSlotAssignment(
                code: code,
                name: name,
                cost: cost,
                patientRef: patientRef,
                notes: notes,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict slot assignment in status draft.
    static func newStrictSlotAssignment(_ code: String, name: String) -> StrictSlotAssignment {
        return StrictSlotAssignment(
            code: code,
            name: name,
            cost: 0.0,
            patientRef: "",
            notes: "",
            tags: [],
            status: StrictSlotAssignmentStatus.draft
        )
    }
}
