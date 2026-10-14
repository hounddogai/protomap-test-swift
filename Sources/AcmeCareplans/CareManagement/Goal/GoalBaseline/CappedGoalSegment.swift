import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped goal segment is in its life cycle.
    enum CappedGoalSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a capped goal segment and its current status.
    final class CappedGoalSegment {
        var code: String
        var title: String
        var updatedAt: Int
        var bed: String
        var checksum: String
        var batchSize: Int
        var status: CappedGoalSegmentStatus

        init(code: String, title: String, updatedAt: Int, bed: String, checksum: String, batchSize: Int, status: CappedGoalSegmentStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.bed = bed
            self.checksum = checksum
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedGoalSegmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == CappedGoalSegmentStatus.suspended || next == CappedGoalSegmentStatus.closed
            case .pending:
                return next == CappedGoalSegmentStatus.active || next == CappedGoalSegmentStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: CappedGoalSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped goal segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedTotal() -> Double {
            return (Double(batchSize) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedGoalSegment {
            return CappedGoalSegment(
                code: code,
                title: title,
                updatedAt: updatedAt,
                bed: bed,
                checksum: checksum,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped goal segment in status draft.
    static func newCappedGoalSegment(_ code: String, title: String) -> CappedGoalSegment {
        return CappedGoalSegment(
            code: code,
            title: title,
            updatedAt: 0,
            bed: "",
            checksum: "",
            batchSize: 0,
            status: CappedGoalSegmentStatus.draft
        )
    }
}
