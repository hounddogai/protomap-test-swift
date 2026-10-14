import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim milestone is in its life cycle.
    enum ClaimMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A claim milestone. Its code is unique within a tenant.
    final class ClaimMilestone {
        var code: String
        var name: String
        var revision: Int
        var createdAt: Int
        var capacity: Int
        var limit: Int
        var margin: Double
        var pinned: Bool
        var summary: String
        var status: ClaimMilestoneStatus

        init(code: String, name: String, revision: Int, createdAt: Int, capacity: Int, limit: Int, margin: Double, pinned: Bool, summary: String, status: ClaimMilestoneStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.createdAt = createdAt
            self.capacity = capacity
            self.limit = limit
            self.margin = margin
            self.pinned = pinned
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClaimMilestoneStatus) -> Bool {
            switch status {
            case .created:
                return next == ClaimMilestoneStatus.published || next == ClaimMilestoneStatus.retired
            case .validated:
                return next == ClaimMilestoneStatus.published || next == ClaimMilestoneStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ClaimMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("claim milestone") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((margin - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimMilestone {
            return ClaimMilestone(
                code: code,
                name: name,
                revision: revision,
                createdAt: createdAt,
                capacity: capacity,
                limit: limit,
                margin: margin,
                pinned: pinned,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a claim milestone in status created.
    static func newClaimMilestone(_ code: String, name: String) -> ClaimMilestone {
        return ClaimMilestone(
            code: code,
            name: name,
            revision: 0,
            createdAt: 0,
            capacity: 0,
            limit: 0,
            margin: 0.0,
            pinned: false,
            summary: "",
            status: ClaimMilestoneStatus.created
        )
    }
}
