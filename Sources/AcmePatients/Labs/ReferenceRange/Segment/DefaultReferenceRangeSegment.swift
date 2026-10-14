import AcmePlatform
import Foundation

extension Labs {
    /// Where a default reference range segment is in its life cycle.
    enum DefaultReferenceRangeSegmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a default reference range segment and its current status.
    final class DefaultReferenceRangeSegment {
        var code: String
        var label: String
        var encounterID: String
        var title: String
        var capacity: Int
        var facility: String
        var batchSize: Int
        var minimum: Double
        var status: DefaultReferenceRangeSegmentStatus

        init(code: String, label: String, encounterID: String, title: String, capacity: Int, facility: String, batchSize: Int, minimum: Double, status: DefaultReferenceRangeSegmentStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.title = title
            self.capacity = capacity
            self.facility = facility
            self.batchSize = batchSize
            self.minimum = minimum
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

        func canMoveTo(_ next: DefaultReferenceRangeSegmentStatus) -> Bool {
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
                return next == DefaultReferenceRangeSegmentStatus.inProgress || next == DefaultReferenceRangeSegmentStatus.completed
            case .inProgress:
                return next == DefaultReferenceRangeSegmentStatus.completed || next == DefaultReferenceRangeSegmentStatus.cancelled
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

        func moveTo(_ next: DefaultReferenceRangeSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default reference range segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedValue() -> Double {
            return ((minimum + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultReferenceRangeSegment {
            return DefaultReferenceRangeSegment(
                code: code,
                label: label,
                encounterID: encounterID,
                title: title,
                capacity: capacity,
                facility: facility,
                batchSize: batchSize,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a default reference range segment in status planned.
    static func newDefaultReferenceRangeSegment(_ code: String, label: String) -> DefaultReferenceRangeSegment {
        return DefaultReferenceRangeSegment(
            code: code,
            label: label,
            encounterID: "",
            title: "",
            capacity: 0,
            facility: "",
            batchSize: 0,
            minimum: 0.0,
            status: DefaultReferenceRangeSegmentStatus.planned
        )
    }
}
