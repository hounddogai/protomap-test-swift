import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional study snapshot is in its life cycle.
    enum RegionalStudySnapshotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One regional study snapshot, with what the planners need to act on it.
    final class RegionalStudySnapshot {
        var code: String
        var name: String
        var label: String
        var endsAt: Int
        var archived: Bool
        var status: RegionalStudySnapshotStatus

        init(code: String, name: String, label: String, endsAt: Int, archived: Bool, status: RegionalStudySnapshotStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.endsAt = endsAt
            self.archived = archived
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

        func canMoveTo(_ next: RegionalStudySnapshotStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
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

        func moveTo(_ next: RegionalStudySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional study snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> RegionalStudySnapshot {
            return RegionalStudySnapshot(
                code: code,
                name: name,
                label: label,
                endsAt: endsAt,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional study snapshot in status planned.
    static func newRegionalStudySnapshot(_ code: String, name: String) -> RegionalStudySnapshot {
        return RegionalStudySnapshot(
            code: code,
            name: name,
            label: "",
            endsAt: 0,
            archived: false,
            status: RegionalStudySnapshotStatus.planned
        )
    }
}
