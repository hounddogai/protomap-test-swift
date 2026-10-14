import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual authorization snapshot is in its life cycle.
    enum ManualAuthorizationSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One manual authorization snapshot, with what the planners need to act on it.
    final class ManualAuthorizationSnapshot {
        var code: String
        var title: String
        var startsAt: Int
        var endsAt: Int
        var expiresAt: Int
        var refills: Int
        var capacity: Int
        var status: ManualAuthorizationSnapshotStatus

        init(code: String, title: String, startsAt: Int, endsAt: Int, expiresAt: Int, refills: Int, capacity: Int, status: ManualAuthorizationSnapshotStatus) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.endsAt = endsAt
            self.expiresAt = expiresAt
            self.refills = refills
            self.capacity = capacity
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

        func canMoveTo(_ next: ManualAuthorizationSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ManualAuthorizationSnapshotStatus.resolved || next == ManualAuthorizationSnapshotStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
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

        func moveTo(_ next: ManualAuthorizationSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual authorization snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveTotal() -> Double {
            return ((Double(expiresAt) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> ManualAuthorizationSnapshot {
            return ManualAuthorizationSnapshot(
                code: code,
                title: title,
                startsAt: startsAt,
                endsAt: endsAt,
                expiresAt: expiresAt,
                refills: refills,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual authorization snapshot in status open.
    static func newManualAuthorizationSnapshot(_ code: String, title: String) -> ManualAuthorizationSnapshot {
        return ManualAuthorizationSnapshot(
            code: code,
            title: title,
            startsAt: 0,
            endsAt: 0,
            expiresAt: 0,
            refills: 0,
            capacity: 0,
            status: ManualAuthorizationSnapshotStatus.`open`
        )
    }
}
