import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched goal snapshot is in its life cycle.
    enum BatchedGoalSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A batched goal snapshot as the goal team keeps it.
    final class BatchedGoalSnapshot {
        var code: String
        var title: String
        var discount: Double
        var pinned: Bool
        var acuity: Int
        var segment: String
        var status: BatchedGoalSnapshotStatus

        init(code: String, title: String, discount: Double, pinned: Bool, acuity: Int, segment: String, status: BatchedGoalSnapshotStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.pinned = pinned
            self.acuity = acuity
            self.segment = segment
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

        func canMoveTo(_ next: BatchedGoalSnapshotStatus) -> Bool {
            switch status {
            case .new:
                return next == BatchedGoalSnapshotStatus.queued || next == BatchedGoalSnapshotStatus.failed
            case .queued:
                return next == BatchedGoalSnapshotStatus.failed
            case .running:
                return next == BatchedGoalSnapshotStatus.done || next == BatchedGoalSnapshotStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: BatchedGoalSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched goal snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedExposure() -> Double {
            return ((Double(acuity) - discount) * 100).rounded() / 100
        }

        func copyValue() -> BatchedGoalSnapshot {
            return BatchedGoalSnapshot(
                code: code,
                title: title,
                discount: discount,
                pinned: pinned,
                acuity: acuity,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched goal snapshot in status new.
    static func newBatchedGoalSnapshot(_ code: String, title: String) -> BatchedGoalSnapshot {
        return BatchedGoalSnapshot(
            code: code,
            title: title,
            discount: 0.0,
            pinned: false,
            acuity: 0,
            segment: "",
            status: BatchedGoalSnapshotStatus.new
        )
    }
}
