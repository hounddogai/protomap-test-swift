import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling cleaning entry is in its life cycle.
    enum RollingCleaningEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One rolling cleaning entry, with what the planners need to act on it.
    final class RollingCleaningEntry {
        var code: String
        var label: String
        var sequence: Int
        var tags: [String]
        var ceiling: Double
        var payer: String
        var retries: Int
        var updatedAt: Int
        var category: String
        var priority: Int
        var status: RollingCleaningEntryStatus

        init(code: String, label: String, sequence: Int, tags: [String], ceiling: Double, payer: String, retries: Int, updatedAt: Int, category: String, priority: Int, status: RollingCleaningEntryStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.tags = tags
            self.ceiling = ceiling
            self.payer = payer
            self.retries = retries
            self.updatedAt = updatedAt
            self.category = category
            self.priority = priority
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

        func canMoveTo(_ next: RollingCleaningEntryStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingCleaningEntryStatus.running
            case .queued:
                return next == RollingCleaningEntryStatus.failed
            case .running:
                return next == RollingCleaningEntryStatus.done || next == RollingCleaningEntryStatus.failed
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

        func moveTo(_ next: RollingCleaningEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling cleaning entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveLoad() -> Double {
            return ((Double(updatedAt) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> RollingCleaningEntry {
            return RollingCleaningEntry(
                code: code,
                label: label,
                sequence: sequence,
                tags: tags,
                ceiling: ceiling,
                payer: payer,
                retries: retries,
                updatedAt: updatedAt,
                category: category,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rolling cleaning entry in status new.
    static func newRollingCleaningEntry(_ code: String, label: String) -> RollingCleaningEntry {
        return RollingCleaningEntry(
            code: code,
            label: label,
            sequence: 0,
            tags: [],
            ceiling: 0.0,
            payer: "",
            retries: 0,
            updatedAt: 0,
            category: "",
            priority: 0,
            status: RollingCleaningEntryStatus.new
        )
    }
}
