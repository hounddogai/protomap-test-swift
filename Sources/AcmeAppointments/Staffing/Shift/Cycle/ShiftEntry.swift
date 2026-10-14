import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift entry is in its life cycle.
    enum ShiftEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A shift entry as the shift team keeps it.
    final class ShiftEntry {
        var code: String
        var name: String
        var encounterID: String
        var minimum: Double
        var category: String
        var tags: [String]
        var status: ShiftEntryStatus

        init(code: String, name: String, encounterID: String, minimum: Double, category: String, tags: [String], status: ShiftEntryStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.minimum = minimum
            self.category = category
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftEntryStatus) -> Bool {
            switch status {
            case .planned:
                return next == ShiftEntryStatus.scheduled || next == ShiftEntryStatus.completed
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ShiftEntryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
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
            return minimum
        }

        func copyValue() -> ShiftEntry {
            return ShiftEntry(
                code: code,
                name: name,
                encounterID: encounterID,
                minimum: minimum,
                category: category,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a shift entry in status planned.
    static func newShiftEntry(_ code: String, name: String) -> ShiftEntry {
        return ShiftEntry(
            code: code,
            name: name,
            encounterID: "",
            minimum: 0.0,
            category: "",
            tags: [],
            status: ShiftEntryStatus.planned
        )
    }
}
