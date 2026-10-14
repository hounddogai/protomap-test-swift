import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory mapping is in its life cycle.
    enum InventoryMappingStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One inventory mapping, with what the planners need to act on it.
    final class InventoryMapping {
        var code: String
        var title: String
        var durationMinutes: Int
        var refills: Int
        var archived: Bool
        var notes: String
        var startsAt: Int
        var status: InventoryMappingStatus

        init(code: String, title: String, durationMinutes: Int, refills: Int, archived: Bool, notes: String, startsAt: Int, status: InventoryMappingStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.refills = refills
            self.archived = archived
            self.notes = notes
            self.startsAt = startsAt
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

        func canMoveTo(_ next: InventoryMappingStatus) -> Bool {
            switch status {
            case .draft:
                return next == InventoryMappingStatus.pending || next == InventoryMappingStatus.closed
            case .pending:
                return next == InventoryMappingStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == InventoryMappingStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netTotal() -> Double {
            return ((Double(refills) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> InventoryMapping {
            return InventoryMapping(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                refills: refills,
                archived: archived,
                notes: notes,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a inventory mapping in status draft.
    static func newInventoryMapping(_ code: String, title: String) -> InventoryMapping {
        return InventoryMapping(
            code: code,
            title: title,
            durationMinutes: 0,
            refills: 0,
            archived: false,
            notes: "",
            startsAt: 0,
            status: InventoryMappingStatus.draft
        )
    }
}
