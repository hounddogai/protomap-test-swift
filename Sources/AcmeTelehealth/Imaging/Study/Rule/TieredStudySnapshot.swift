import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered study snapshot is in its life cycle.
    enum TieredStudySnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One tiered study snapshot, with what the planners need to act on it.
    final class TieredStudySnapshot {
        var code: String
        var title: String
        var country: String
        var visitMinutes: Int
        var refills: Int
        var threshold: Double
        var status: TieredStudySnapshotStatus

        init(code: String, title: String, country: String, visitMinutes: Int, refills: Int, threshold: Double, status: TieredStudySnapshotStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.visitMinutes = visitMinutes
            self.refills = refills
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredStudySnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TieredStudySnapshotStatus.inReview
            case .inReview:
                return next == TieredStudySnapshotStatus.archived
            case .resolved:
                return next == TieredStudySnapshotStatus.reopened
            case .reopened:
                return next == TieredStudySnapshotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredStudySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered study snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netValue() -> Double {
            return ((Double(visitMinutes) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> TieredStudySnapshot {
            return TieredStudySnapshot(
                code: code,
                title: title,
                country: country,
                visitMinutes: visitMinutes,
                refills: refills,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered study snapshot in status open.
    static func newTieredStudySnapshot(_ code: String, title: String) -> TieredStudySnapshot {
        return TieredStudySnapshot(
            code: code,
            title: title,
            country: "",
            visitMinutes: 0,
            refills: 0,
            threshold: 0.0,
            status: TieredStudySnapshotStatus.`open`
        )
    }
}
