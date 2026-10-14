import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal panel entry is in its life cycle.
    enum SeasonalPanelEntryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One seasonal panel entry, with what the planners need to act on it.
    final class SeasonalPanelEntry {
        var code: String
        var label: String
        var reviewer: String
        var priority: Int
        var bed: String
        var status: SeasonalPanelEntryStatus

        init(code: String, label: String, reviewer: String, priority: Int, bed: String, status: SeasonalPanelEntryStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.priority = priority
            self.bed = bed
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

        func canMoveTo(_ next: SeasonalPanelEntryStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == SeasonalPanelEntryStatus.reopened || next == SeasonalPanelEntryStatus.archived
            case .resolved:
                return next == SeasonalPanelEntryStatus.reopened
            case .reopened:
                return next == SeasonalPanelEntryStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalPanelEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal panel entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> SeasonalPanelEntry {
            return SeasonalPanelEntry(
                code: code,
                label: label,
                reviewer: reviewer,
                priority: priority,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal panel entry in status open.
    static func newSeasonalPanelEntry(_ code: String, label: String) -> SeasonalPanelEntry {
        return SeasonalPanelEntry(
            code: code,
            label: label,
            reviewer: "",
            priority: 0,
            bed: "",
            status: SeasonalPanelEntryStatus.`open`
        )
    }
}
