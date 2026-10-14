import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier assignment is in its life cycle.
    enum CourierAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One courier assignment, with what the planners need to act on it.
    final class CourierAssignment {
        var code: String
        var name: String
        var locale: String
        var checksum: String
        var externalRef: String
        var pinned: Bool
        var title: String
        var score: Double
        var status: CourierAssignmentStatus

        init(code: String, name: String, locale: String, checksum: String, externalRef: String, pinned: Bool, title: String, score: Double, status: CourierAssignmentStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.checksum = checksum
            self.externalRef = externalRef
            self.pinned = pinned
            self.title = title
            self.score = score
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

        func canMoveTo(_ next: CourierAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
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
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CourierAssignmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> CourierAssignment {
            return CourierAssignment(
                code: code,
                name: name,
                locale: locale,
                checksum: checksum,
                externalRef: externalRef,
                pinned: pinned,
                title: title,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a courier assignment in status planned.
    static func newCourierAssignment(_ code: String, name: String) -> CourierAssignment {
        return CourierAssignment(
            code: code,
            name: name,
            locale: "",
            checksum: "",
            externalRef: "",
            pinned: false,
            title: "",
            score: 0.0,
            status: CourierAssignmentStatus.planned
        )
    }
}
