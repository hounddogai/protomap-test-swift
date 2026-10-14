import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback worklist review is in its life cycle.
    enum FallbackWorklistReviewStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback worklist review as the worklist team keeps it.
    final class FallbackWorklistReview {
        var code: String
        var name: String
        var refills: Int
        var patientRef: String
        var batchSize: Int
        var notes: String
        var bed: String
        var visible: Bool
        var status: FallbackWorklistReviewStatus

        init(code: String, name: String, refills: Int, patientRef: String, batchSize: Int, notes: String, bed: String, visible: Bool, status: FallbackWorklistReviewStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.notes = notes
            self.bed = bed
            self.visible = visible
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

        func canMoveTo(_ next: FallbackWorklistReviewStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == FallbackWorklistReviewStatus.completed
            case .inProgress:
                return next == FallbackWorklistReviewStatus.completed || next == FallbackWorklistReviewStatus.cancelled
            case .completed:
                return next == FallbackWorklistReviewStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackWorklistReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback worklist review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback worklist review") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(refills) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackWorklistReview {
            return FallbackWorklistReview(
                code: code,
                name: name,
                refills: refills,
                patientRef: patientRef,
                batchSize: batchSize,
                notes: notes,
                bed: bed,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback worklist review in status planned.
    static func newFallbackWorklistReview(_ code: String, name: String) -> FallbackWorklistReview {
        return FallbackWorklistReview(
            code: code,
            name: name,
            refills: 0,
            patientRef: "",
            batchSize: 0,
            notes: "",
            bed: "",
            visible: false,
            status: FallbackWorklistReviewStatus.planned
        )
    }
}
