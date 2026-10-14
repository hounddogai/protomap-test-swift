import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual closure rollup is in its life cycle.
    enum ManualClosureRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A manual closure rollup as the closure team keeps it.
    final class ManualClosureRollup {
        var code: String
        var title: String
        var visitMinutes: Int
        var bed: String
        var name: String
        var status: ManualClosureRollupStatus

        init(code: String, title: String, visitMinutes: Int, bed: String, name: String, status: ManualClosureRollupStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.bed = bed
            self.name = name
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

        func canMoveTo(_ next: ManualClosureRollupStatus) -> Bool {
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
                return next == ManualClosureRollupStatus.inProgress
            case .inProgress:
                return next == ManualClosureRollupStatus.cancelled
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

        func moveTo(_ next: ManualClosureRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual closure rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> ManualClosureRollup {
            return ManualClosureRollup(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                bed: bed,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual closure rollup in status planned.
    static func newManualClosureRollup(_ code: String, title: String) -> ManualClosureRollup {
        return ManualClosureRollup(
            code: code,
            title: title,
            visitMinutes: 0,
            bed: "",
            name: "",
            status: ManualClosureRollupStatus.planned
        )
    }
}
