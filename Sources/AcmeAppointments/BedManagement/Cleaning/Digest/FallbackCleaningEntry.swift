import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback cleaning entry is in its life cycle.
    enum FallbackCleaningEntryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One fallback cleaning entry, with what the planners need to act on it.
    final class FallbackCleaningEntry {
        var code: String
        var name: String
        var title: String
        var source: String
        var category: String
        var currency: String
        var windowDays: Int
        var timezone: String
        var status: FallbackCleaningEntryStatus

        init(code: String, name: String, title: String, source: String, category: String, currency: String, windowDays: Int, timezone: String, status: FallbackCleaningEntryStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.source = source
            self.category = category
            self.currency = currency
            self.windowDays = windowDays
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackCleaningEntryStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == FallbackCleaningEntryStatus.resolved || next == FallbackCleaningEntryStatus.archived
            case .resolved:
                return next == FallbackCleaningEntryStatus.archived
            case .reopened:
                return next == FallbackCleaningEntryStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCleaningEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback cleaning entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> FallbackCleaningEntry {
            return FallbackCleaningEntry(
                code: code,
                name: name,
                title: title,
                source: source,
                category: category,
                currency: currency,
                windowDays: windowDays,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a fallback cleaning entry in status open.
    static func newFallbackCleaningEntry(_ code: String, name: String) -> FallbackCleaningEntry {
        return FallbackCleaningEntry(
            code: code,
            name: name,
            title: "",
            source: "",
            category: "",
            currency: "",
            windowDays: 0,
            timezone: "",
            status: FallbackCleaningEntryStatus.`open`
        )
    }
}
