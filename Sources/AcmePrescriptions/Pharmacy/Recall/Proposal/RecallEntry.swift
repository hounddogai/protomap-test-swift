import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall entry is in its life cycle.
    enum RecallEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One recall entry, with what the planners need to act on it.
    final class RecallEntry {
        var code: String
        var name: String
        var contactEmail: String
        var archived: Bool
        var margin: Double
        var status: RecallEntryStatus

        init(code: String, name: String, contactEmail: String, archived: Bool, margin: Double, status: RecallEntryStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.archived = archived
            self.margin = margin
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

        func canMoveTo(_ next: RecallEntryStatus) -> Bool {
            switch status {
            case .new:
                return next == RecallEntryStatus.done || next == RecallEntryStatus.failed
            case .queued:
                return next == RecallEntryStatus.running || next == RecallEntryStatus.done
            case .running:
                return next == RecallEntryStatus.done || next == RecallEntryStatus.failed
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

        func moveTo(_ next: RecallEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("recall entry") \(code)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> RecallEntry {
            return RecallEntry(
                code: code,
                name: name,
                contactEmail: contactEmail,
                archived: archived,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a recall entry in status new.
    static func newRecallEntry(_ code: String, name: String) -> RecallEntry {
        return RecallEntry(
            code: code,
            name: name,
            contactEmail: "",
            archived: false,
            margin: 0.0,
            status: RecallEntryStatus.new
        )
    }
}
