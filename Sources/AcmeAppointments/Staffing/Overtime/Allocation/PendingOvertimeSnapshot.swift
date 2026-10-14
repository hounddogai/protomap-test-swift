import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending overtime snapshot is in its life cycle.
    enum PendingOvertimeSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One pending overtime snapshot, with what the planners need to act on it.
    final class PendingOvertimeSnapshot {
        var code: String
        var title: String
        var threshold: Double
        var tags: [String]
        var dosageMg: Double
        var cost: Double
        var status: PendingOvertimeSnapshotStatus

        init(code: String, title: String, threshold: Double, tags: [String], dosageMg: Double, cost: Double, status: PendingOvertimeSnapshotStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.tags = tags
            self.dosageMg = dosageMg
            self.cost = cost
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

        func canMoveTo(_ next: PendingOvertimeSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingOvertimeSnapshotStatus.resolved || next == PendingOvertimeSnapshotStatus.reopened
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PendingOvertimeSnapshotStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PendingOvertimeSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending overtime snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netValue() -> Double {
            return ((threshold + cost) * 100).rounded() / 100
        }

        func copyValue() -> PendingOvertimeSnapshot {
            return PendingOvertimeSnapshot(
                code: code,
                title: title,
                threshold: threshold,
                tags: tags,
                dosageMg: dosageMg,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending overtime snapshot in status open.
    static func newPendingOvertimeSnapshot(_ code: String, title: String) -> PendingOvertimeSnapshot {
        return PendingOvertimeSnapshot(
            code: code,
            title: title,
            threshold: 0.0,
            tags: [],
            dosageMg: 0.0,
            cost: 0.0,
            status: PendingOvertimeSnapshotStatus.`open`
        )
    }
}
