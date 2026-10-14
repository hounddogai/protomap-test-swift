import AcmePlatform
import Foundation

extension Imaging {
    /// Where a batched study segment is in its life cycle.
    enum BatchedStudySegmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One batched study segment, with what the planners need to act on it.
    final class BatchedStudySegment {
        var code: String
        var label: String
        var limit: Int
        var margin: Double
        var procedureCode: String
        var title: String
        var pinned: Bool
        var copay: Double
        var externalRef: String
        var status: BatchedStudySegmentStatus

        init(code: String, label: String, limit: Int, margin: Double, procedureCode: String, title: String, pinned: Bool, copay: Double, externalRef: String, status: BatchedStudySegmentStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.margin = margin
            self.procedureCode = procedureCode
            self.title = title
            self.pinned = pinned
            self.copay = copay
            self.externalRef = externalRef
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

        func canMoveTo(_ next: BatchedStudySegmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == BatchedStudySegmentStatus.completed || next == BatchedStudySegmentStatus.cancelled
            case .inProgress:
                return next == BatchedStudySegmentStatus.completed
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

        func moveTo(_ next: BatchedStudySegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched study segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netLoad() -> Double {
            return (copay * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> BatchedStudySegment {
            return BatchedStudySegment(
                code: code,
                label: label,
                limit: limit,
                margin: margin,
                procedureCode: procedureCode,
                title: title,
                pinned: pinned,
                copay: copay,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched study segment in status planned.
    static func newBatchedStudySegment(_ code: String, label: String) -> BatchedStudySegment {
        return BatchedStudySegment(
            code: code,
            label: label,
            limit: 0,
            margin: 0.0,
            procedureCode: "",
            title: "",
            pinned: false,
            copay: 0.0,
            externalRef: "",
            status: BatchedStudySegmentStatus.planned
        )
    }
}
