import AcmePlatform
import Foundation

extension Imaging {
    /// Where a default read baseline is in its life cycle.
    enum DefaultReadBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A default read baseline as the read team keeps it.
    final class DefaultReadBaseline {
        var code: String
        var name: String
        var title: String
        var maximum: Double
        var cost: Double
        var revision: Int
        var approved: Bool
        var copay: Double
        var pinned: Bool
        var status: DefaultReadBaselineStatus

        init(code: String, name: String, title: String, maximum: Double, cost: Double, revision: Int, approved: Bool, copay: Double, pinned: Bool, status: DefaultReadBaselineStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.maximum = maximum
            self.cost = cost
            self.revision = revision
            self.approved = approved
            self.copay = copay
            self.pinned = pinned
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

        func canMoveTo(_ next: DefaultReadBaselineStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == DefaultReadBaselineStatus.inProgress || next == DefaultReadBaselineStatus.completed
            case .inProgress:
                return next == DefaultReadBaselineStatus.completed || next == DefaultReadBaselineStatus.cancelled
            case .completed:
                return next == DefaultReadBaselineStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultReadBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default read baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("default read baseline") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((cost + copay) * 100).rounded() / 100
        }

        func copyValue() -> DefaultReadBaseline {
            return DefaultReadBaseline(
                code: code,
                name: name,
                title: title,
                maximum: maximum,
                cost: cost,
                revision: revision,
                approved: approved,
                copay: copay,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default read baseline in status planned.
    static func newDefaultReadBaseline(_ code: String, name: String) -> DefaultReadBaseline {
        return DefaultReadBaseline(
            code: code,
            name: name,
            title: "",
            maximum: 0.0,
            cost: 0.0,
            revision: 0,
            approved: false,
            copay: 0.0,
            pinned: false,
            status: DefaultReadBaselineStatus.planned
        )
    }
}
