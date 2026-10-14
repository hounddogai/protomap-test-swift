import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict read snapshot is in its life cycle.
    enum StrictReadSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a strict read snapshot and its current status.
    final class StrictReadSnapshot {
        var code: String
        var title: String
        var priority: Int
        var approved: Bool
        var name: String
        var status: StrictReadSnapshotStatus

        init(code: String, title: String, priority: Int, approved: Bool, name: String, status: StrictReadSnapshotStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.approved = approved
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictReadSnapshotStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictReadSnapshotStatus.running
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == StrictReadSnapshotStatus.done || next == StrictReadSnapshotStatus.failed
            case .done:
                return next == StrictReadSnapshotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictReadSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict read snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> StrictReadSnapshot {
            return StrictReadSnapshot(
                code: code,
                title: title,
                priority: priority,
                approved: approved,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict read snapshot in status new.
    static func newStrictReadSnapshot(_ code: String, title: String) -> StrictReadSnapshot {
        return StrictReadSnapshot(
            code: code,
            title: title,
            priority: 0,
            approved: false,
            name: "",
            status: StrictReadSnapshotStatus.new
        )
    }
}
