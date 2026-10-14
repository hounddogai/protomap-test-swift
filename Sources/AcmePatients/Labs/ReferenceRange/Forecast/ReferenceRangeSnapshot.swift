import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range snapshot is in its life cycle.
    enum ReferenceRangeSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A reference range snapshot as the reference range team keeps it.
    final class ReferenceRangeSnapshot {
        var code: String
        var title: String
        var archived: Bool
        var copay: Double
        var score: Double
        var cost: Double
        var revision: Int
        var channel: String
        var ceiling: Double
        var refills: Int
        var visitMinutes: Int
        var status: ReferenceRangeSnapshotStatus

        init(code: String, title: String, archived: Bool, copay: Double, score: Double, cost: Double, revision: Int, channel: String, ceiling: Double, refills: Int, visitMinutes: Int, status: ReferenceRangeSnapshotStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.copay = copay
            self.score = score
            self.cost = cost
            self.revision = revision
            self.channel = channel
            self.ceiling = ceiling
            self.refills = refills
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: ReferenceRangeSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ReferenceRangeSnapshotStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ReferenceRangeSnapshotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedValue() -> Double {
            return ((cost + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeSnapshot {
            return ReferenceRangeSnapshot(
                code: code,
                title: title,
                archived: archived,
                copay: copay,
                score: score,
                cost: cost,
                revision: revision,
                channel: channel,
                ceiling: ceiling,
                refills: refills,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a reference range snapshot in status open.
    static func newReferenceRangeSnapshot(_ code: String, title: String) -> ReferenceRangeSnapshot {
        return ReferenceRangeSnapshot(
            code: code,
            title: title,
            archived: false,
            copay: 0.0,
            score: 0.0,
            cost: 0.0,
            revision: 0,
            channel: "",
            ceiling: 0.0,
            refills: 0,
            visitMinutes: 0,
            status: ReferenceRangeSnapshotStatus.`open`
        )
    }
}
