import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global goal entry is in its life cycle.
    enum GlobalGoalEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One global goal entry, with what the planners need to act on it.
    final class GlobalGoalEntry {
        var code: String
        var label: String
        var priority: Int
        var windowDays: Int
        var createdAt: Int
        var limit: Int
        var ratio: Double
        var contactEmail: String
        var rate: Double
        var ownerID: String
        var status: GlobalGoalEntryStatus

        init(code: String, label: String, priority: Int, windowDays: Int, createdAt: Int, limit: Int, ratio: Double, contactEmail: String, rate: Double, ownerID: String, status: GlobalGoalEntryStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.windowDays = windowDays
            self.createdAt = createdAt
            self.limit = limit
            self.ratio = ratio
            self.contactEmail = contactEmail
            self.rate = rate
            self.ownerID = ownerID
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

        func canMoveTo(_ next: GlobalGoalEntryStatus) -> Bool {
            switch status {
            case .planned:
                return next == GlobalGoalEntryStatus.scheduled || next == GlobalGoalEntryStatus.completed
            case .scheduled:
                return next == GlobalGoalEntryStatus.inProgress
            case .inProgress:
                return next == GlobalGoalEntryStatus.cancelled
            case .completed:
                return next == GlobalGoalEntryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalGoalEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global goal entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedTotal() -> Double {
            return ((Double(priority) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalGoalEntry {
            return GlobalGoalEntry(
                code: code,
                label: label,
                priority: priority,
                windowDays: windowDays,
                createdAt: createdAt,
                limit: limit,
                ratio: ratio,
                contactEmail: contactEmail,
                rate: rate,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global goal entry in status planned.
    static func newGlobalGoalEntry(_ code: String, label: String) -> GlobalGoalEntry {
        return GlobalGoalEntry(
            code: code,
            label: label,
            priority: 0,
            windowDays: 0,
            createdAt: 0,
            limit: 0,
            ratio: 0.0,
            contactEmail: "",
            rate: 0.0,
            ownerID: "",
            status: GlobalGoalEntryStatus.planned
        )
    }
}
