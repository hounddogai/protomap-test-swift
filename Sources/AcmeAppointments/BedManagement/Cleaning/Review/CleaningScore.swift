import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning score is in its life cycle.
    enum CleaningScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A cleaning score as the cleaning team keeps it.
    final class CleaningScore {
        var code: String
        var label: String
        var priority: Int
        var title: String
        var approved: Bool
        var summary: String
        var status: CleaningScoreStatus

        init(code: String, label: String, priority: Int, title: String, approved: Bool, summary: String, status: CleaningScoreStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.title = title
            self.approved = approved
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CleaningScoreStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CleaningScoreStatus.rejected || next == CleaningScoreStatus.withdrawn
            case .rejected:
                return next == CleaningScoreStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("cleaning score") \(code)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> CleaningScore {
            return CleaningScore(
                code: code,
                label: label,
                priority: priority,
                title: title,
                approved: approved,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a cleaning score in status proposed.
    static func newCleaningScore(_ code: String, label: String) -> CleaningScore {
        return CleaningScore(
            code: code,
            label: label,
            priority: 0,
            title: "",
            approved: false,
            summary: "",
            status: CleaningScoreStatus.proposed
        )
    }
}
