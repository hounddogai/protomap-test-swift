import AcmePlatform
import Foundation

extension Referrals {
    /// Where a lenient network snapshot is in its life cycle.
    enum LenientNetworkSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One lenient network snapshot, with what the planners need to act on it.
    final class LenientNetworkSnapshot {
        var code: String
        var name: String
        var payer: String
        var margin: Double
        var graceDays: Int
        var capacity: Int
        var archived: Bool
        var status: LenientNetworkSnapshotStatus

        init(code: String, name: String, payer: String, margin: Double, graceDays: Int, capacity: Int, archived: Bool, status: LenientNetworkSnapshotStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.margin = margin
            self.graceDays = graceDays
            self.capacity = capacity
            self.archived = archived
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

        func canMoveTo(_ next: LenientNetworkSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientNetworkSnapshotStatus.resolved || next == LenientNetworkSnapshotStatus.reopened
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LenientNetworkSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient network snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient network snapshot") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(capacity) + margin) * 100).rounded() / 100
        }

        func copyValue() -> LenientNetworkSnapshot {
            return LenientNetworkSnapshot(
                code: code,
                name: name,
                payer: payer,
                margin: margin,
                graceDays: graceDays,
                capacity: capacity,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient network snapshot in status open.
    static func newLenientNetworkSnapshot(_ code: String, name: String) -> LenientNetworkSnapshot {
        return LenientNetworkSnapshot(
            code: code,
            name: name,
            payer: "",
            margin: 0.0,
            graceDays: 0,
            capacity: 0,
            archived: false,
            status: LenientNetworkSnapshotStatus.`open`
        )
    }
}
