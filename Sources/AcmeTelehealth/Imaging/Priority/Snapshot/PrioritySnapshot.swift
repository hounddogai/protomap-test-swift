import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority snapshot is in its life cycle.
    enum PrioritySnapshotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a priority snapshot and its current status.
    final class PrioritySnapshot {
        var code: String
        var label: String
        var ratio: Double
        var contactEmail: String
        var dosageMg: Double
        var source: String
        var bed: String
        var status: PrioritySnapshotStatus

        init(code: String, label: String, ratio: Double, contactEmail: String, dosageMg: Double, source: String, bed: String, status: PrioritySnapshotStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.contactEmail = contactEmail
            self.dosageMg = dosageMg
            self.source = source
            self.bed = bed
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

        func canMoveTo(_ next: PrioritySnapshotStatus) -> Bool {
            switch status {
            case .planned:
                return next == PrioritySnapshotStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PrioritySnapshotStatus.cancelled
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

        func moveTo(_ next: PrioritySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedLoad() -> Double {
            return ((dosageMg - ratio) * 100).rounded() / 100
        }

        func copyValue() -> PrioritySnapshot {
            return PrioritySnapshot(
                code: code,
                label: label,
                ratio: ratio,
                contactEmail: contactEmail,
                dosageMg: dosageMg,
                source: source,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a priority snapshot in status planned.
    static func newPrioritySnapshot(_ code: String, label: String) -> PrioritySnapshot {
        return PrioritySnapshot(
            code: code,
            label: label,
            ratio: 0.0,
            contactEmail: "",
            dosageMg: 0.0,
            source: "",
            bed: "",
            status: PrioritySnapshotStatus.planned
        )
    }
}
