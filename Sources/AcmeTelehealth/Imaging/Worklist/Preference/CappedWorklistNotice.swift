import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped worklist notice is in its life cycle.
    enum CappedWorklistNoticeStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One capped worklist notice, with what the planners need to act on it.
    final class CappedWorklistNotice {
        var code: String
        var label: String
        var approved: Bool
        var tags: [String]
        var margin: Double
        var updatedAt: Int
        var priority: Int
        var reviewer: String
        var status: CappedWorklistNoticeStatus

        init(code: String, label: String, approved: Bool, tags: [String], margin: Double, updatedAt: Int, priority: Int, reviewer: String, status: CappedWorklistNoticeStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.tags = tags
            self.margin = margin
            self.updatedAt = updatedAt
            self.priority = priority
            self.reviewer = reviewer
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

        func canMoveTo(_ next: CappedWorklistNoticeStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CappedWorklistNoticeStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: CappedWorklistNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped worklist notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("capped worklist notice") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedTotal() -> Double {
            return ((margin + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedWorklistNotice {
            return CappedWorklistNotice(
                code: code,
                label: label,
                approved: approved,
                tags: tags,
                margin: margin,
                updatedAt: updatedAt,
                priority: priority,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped worklist notice in status planned.
    static func newCappedWorklistNotice(_ code: String, label: String) -> CappedWorklistNotice {
        return CappedWorklistNotice(
            code: code,
            label: label,
            approved: false,
            tags: [],
            margin: 0.0,
            updatedAt: 0,
            priority: 0,
            reviewer: "",
            status: CappedWorklistNoticeStatus.planned
        )
    }
}
