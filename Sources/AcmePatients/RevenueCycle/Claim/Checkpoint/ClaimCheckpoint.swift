import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim checkpoint is in its life cycle.
    enum ClaimCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A claim checkpoint as the claim team keeps it.
    final class ClaimCheckpoint {
        var code: String
        var name: String
        var batchSize: Int
        var endsAt: Int
        var pinned: Bool
        var status: ClaimCheckpointStatus

        init(code: String, name: String, batchSize: Int, endsAt: Int, pinned: Bool, status: ClaimCheckpointStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.endsAt = endsAt
            self.pinned = pinned
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

        func canMoveTo(_ next: ClaimCheckpointStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ClaimCheckpointStatus.reopened || next == ClaimCheckpointStatus.archived
            case .resolved:
                return next == ClaimCheckpointStatus.reopened
            case .reopened:
                return next == ClaimCheckpointStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveExposure() -> Double {
            return ((Double(batchSize) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimCheckpoint {
            return ClaimCheckpoint(
                code: code,
                name: name,
                batchSize: batchSize,
                endsAt: endsAt,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a claim checkpoint in status open.
    static func newClaimCheckpoint(_ code: String, name: String) -> ClaimCheckpoint {
        return ClaimCheckpoint(
            code: code,
            name: name,
            batchSize: 0,
            endsAt: 0,
            pinned: false,
            status: ClaimCheckpointStatus.`open`
        )
    }
}
