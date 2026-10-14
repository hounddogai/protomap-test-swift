import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist cycle is in its life cycle.
    enum WorklistCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One worklist cycle, with what the planners need to act on it.
    final class WorklistCycle {
        var code: String
        var name: String
        var archived: Bool
        var priority: Int
        var clinicianID: String
        var cost: Double
        var sequence: Int
        var discount: Double
        var revision: Int
        var startsAt: Int
        var approved: Bool
        var status: WorklistCycleStatus

        init(code: String, name: String, archived: Bool, priority: Int, clinicianID: String, cost: Double, sequence: Int, discount: Double, revision: Int, startsAt: Int, approved: Bool, status: WorklistCycleStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.priority = priority
            self.clinicianID = clinicianID
            self.cost = cost
            self.sequence = sequence
            self.discount = discount
            self.revision = revision
            self.startsAt = startsAt
            self.approved = approved
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

        func canMoveTo(_ next: WorklistCycleStatus) -> Bool {
            switch status {
            case .draft:
                return next == WorklistCycleStatus.pending || next == WorklistCycleStatus.suspended
            case .pending:
                return next == WorklistCycleStatus.active || next == WorklistCycleStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == WorklistCycleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveTotal() -> Double {
            return ((Double(priority) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistCycle {
            return WorklistCycle(
                code: code,
                name: name,
                archived: archived,
                priority: priority,
                clinicianID: clinicianID,
                cost: cost,
                sequence: sequence,
                discount: discount,
                revision: revision,
                startsAt: startsAt,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a worklist cycle in status draft.
    static func newWorklistCycle(_ code: String, name: String) -> WorklistCycle {
        return WorklistCycle(
            code: code,
            name: name,
            archived: false,
            priority: 0,
            clinicianID: "",
            cost: 0.0,
            sequence: 0,
            discount: 0.0,
            revision: 0,
            startsAt: 0,
            approved: false,
            status: WorklistCycleStatus.draft
        )
    }
}
