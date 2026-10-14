import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist snapshot is in its life cycle.
    enum WorklistSnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a worklist snapshot and its current status.
    final class WorklistSnapshot {
        var code: String
        var title: String
        var rate: Double
        var cost: Double
        var ratio: Double
        var status: WorklistSnapshotStatus

        init(code: String, title: String, rate: Double, cost: Double, ratio: Double, status: WorklistSnapshotStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.cost = cost
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistSnapshotStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == WorklistSnapshotStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedValue() -> Double {
            return (cost * ratio * 100).rounded() / 100
        }

        func copyValue() -> WorklistSnapshot {
            return WorklistSnapshot(code: code, title: title, rate: rate, cost: cost, ratio: ratio, status: status)
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a worklist snapshot in status created.
    static func newWorklistSnapshot(_ code: String, title: String) -> WorklistSnapshot {
        return WorklistSnapshot(
            code: code,
            title: title,
            rate: 0.0,
            cost: 0.0,
            ratio: 0.0,
            status: WorklistSnapshotStatus.created
        )
    }
}
