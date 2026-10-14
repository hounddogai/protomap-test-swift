import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled language cycle is in its life cycle.
    enum ScheduledLanguageCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A scheduled language cycle. Its code is unique within a tenant.
    final class ScheduledLanguageCycle {
        var code: String
        var title: String
        var reviewer: String
        var sequence: Int
        var description: String
        var rate: Double
        var status: ScheduledLanguageCycleStatus

        init(code: String, title: String, reviewer: String, sequence: Int, description: String, rate: Double, status: ScheduledLanguageCycleStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.sequence = sequence
            self.description = description
            self.rate = rate
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

        func canMoveTo(_ next: ScheduledLanguageCycleStatus) -> Bool {
            switch status {
            case .draft:
                return next == ScheduledLanguageCycleStatus.pending || next == ScheduledLanguageCycleStatus.suspended
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ScheduledLanguageCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled language cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveValue() -> Double {
            return ((rate - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledLanguageCycle {
            return ScheduledLanguageCycle(
                code: code,
                title: title,
                reviewer: reviewer,
                sequence: sequence,
                description: description,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled language cycle in status draft.
    static func newScheduledLanguageCycle(_ code: String, title: String) -> ScheduledLanguageCycle {
        return ScheduledLanguageCycle(
            code: code,
            title: title,
            reviewer: "",
            sequence: 0,
            description: "",
            rate: 0.0,
            status: ScheduledLanguageCycleStatus.draft
        )
    }
}
