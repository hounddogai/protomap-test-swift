import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback priority target is in its life cycle.
    enum FallbackPriorityTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback priority target. Its code is unique within a tenant.
    final class FallbackPriorityTarget {
        var code: String
        var title: String
        var maximum: Double
        var limit: Int
        var contactEmail: String
        var status: FallbackPriorityTargetStatus

        init(code: String, title: String, maximum: Double, limit: Int, contactEmail: String, status: FallbackPriorityTargetStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.limit = limit
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: FallbackPriorityTargetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
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
                return next == FallbackPriorityTargetStatus.completed || next == FallbackPriorityTargetStatus.cancelled
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

        func moveTo(_ next: FallbackPriorityTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback priority target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedLoad() -> Double {
            return (maximum * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> FallbackPriorityTarget {
            return FallbackPriorityTarget(
                code: code,
                title: title,
                maximum: maximum,
                limit: limit,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback priority target in status planned.
    static func newFallbackPriorityTarget(_ code: String, title: String) -> FallbackPriorityTarget {
        return FallbackPriorityTarget(
            code: code,
            title: title,
            maximum: 0.0,
            limit: 0,
            contactEmail: "",
            status: FallbackPriorityTargetStatus.planned
        )
    }
}
