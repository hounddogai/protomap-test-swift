import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal segment is in its life cycle.
    enum GoalSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A goal segment as the goal team keeps it.
    final class GoalSegment {
        var code: String
        var title: String
        var contactEmail: String
        var pinned: Bool
        var country: String
        var windowDays: Int
        var threshold: Double
        var status: GoalSegmentStatus

        init(code: String, title: String, contactEmail: String, pinned: Bool, country: String, windowDays: Int, threshold: Double, status: GoalSegmentStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.pinned = pinned
            self.country = country
            self.windowDays = windowDays
            self.threshold = threshold
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

        func canMoveTo(_ next: GoalSegmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
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
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == GoalSegmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedExposure() -> Double {
            return (threshold * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> GoalSegment {
            return GoalSegment(
                code: code,
                title: title,
                contactEmail: contactEmail,
                pinned: pinned,
                country: country,
                windowDays: windowDays,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a goal segment in status draft.
    static func newGoalSegment(_ code: String, title: String) -> GoalSegment {
        return GoalSegment(
            code: code,
            title: title,
            contactEmail: "",
            pinned: false,
            country: "",
            windowDays: 0,
            threshold: 0.0,
            status: GoalSegmentStatus.draft
        )
    }
}
