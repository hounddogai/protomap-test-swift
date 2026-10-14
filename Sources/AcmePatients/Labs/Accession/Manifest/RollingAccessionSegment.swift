import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling accession segment is in its life cycle.
    enum RollingAccessionSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One rolling accession segment, with what the planners need to act on it.
    final class RollingAccessionSegment {
        var code: String
        var label: String
        var copay: Double
        var retries: Int
        var archived: Bool
        var ward: String
        var status: RollingAccessionSegmentStatus

        init(code: String, label: String, copay: Double, retries: Int, archived: Bool, ward: String, status: RollingAccessionSegmentStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.retries = retries
            self.archived = archived
            self.ward = ward
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

        func canMoveTo(_ next: RollingAccessionSegmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == RollingAccessionSegmentStatus.suspended || next == RollingAccessionSegmentStatus.closed
            case .pending:
                return next == RollingAccessionSegmentStatus.active || next == RollingAccessionSegmentStatus.closed
            case .active:
                return next == RollingAccessionSegmentStatus.closed
            case .suspended:
                return next == RollingAccessionSegmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingAccessionSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling accession segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedTotal() -> Double {
            return ((copay + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> RollingAccessionSegment {
            return RollingAccessionSegment(
                code: code,
                label: label,
                copay: copay,
                retries: retries,
                archived: archived,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a rolling accession segment in status draft.
    static func newRollingAccessionSegment(_ code: String, label: String) -> RollingAccessionSegment {
        return RollingAccessionSegment(
            code: code,
            label: label,
            copay: 0.0,
            retries: 0,
            archived: false,
            ward: "",
            status: RollingAccessionSegmentStatus.draft
        )
    }
}
