import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling bed board draft is in its life cycle.
    enum RollingBedBoardDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One rolling bed board draft, with what the planners need to act on it.
    final class RollingBedBoardDraft {
        var code: String
        var name: String
        var dosageMg: Double
        var priority: Int
        var archived: Bool
        var status: RollingBedBoardDraftStatus

        init(code: String, name: String, dosageMg: Double, priority: Int, archived: Bool, status: RollingBedBoardDraftStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.priority = priority
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingBedBoardDraftStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingBedBoardDraftStatus.retired
            case .validated:
                return next == RollingBedBoardDraftStatus.published || next == RollingBedBoardDraftStatus.retired
            case .published:
                return next == RollingBedBoardDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingBedBoardDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling bed board draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedTotal() -> Double {
            return (Double(priority) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> RollingBedBoardDraft {
            return RollingBedBoardDraft(
                code: code,
                name: name,
                dosageMg: dosageMg,
                priority: priority,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling bed board draft in status created.
    static func newRollingBedBoardDraft(_ code: String, name: String) -> RollingBedBoardDraft {
        return RollingBedBoardDraft(
            code: code,
            name: name,
            dosageMg: 0.0,
            priority: 0,
            archived: false,
            status: RollingBedBoardDraftStatus.created
        )
    }
}
