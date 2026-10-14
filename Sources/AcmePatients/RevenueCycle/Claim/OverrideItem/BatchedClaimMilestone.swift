import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched claim milestone is in its life cycle.
    enum BatchedClaimMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A batched claim milestone as the claim team keeps it.
    final class BatchedClaimMilestone {
        var code: String
        var title: String
        var createdAt: Int
        var visitMinutes: Int
        var unit: String
        var active: Bool
        var status: BatchedClaimMilestoneStatus

        init(code: String, title: String, createdAt: Int, visitMinutes: Int, unit: String, active: Bool, status: BatchedClaimMilestoneStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
            self.unit = unit
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedClaimMilestoneStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == BatchedClaimMilestoneStatus.cancelled
            case .inProgress:
                return next == BatchedClaimMilestoneStatus.completed || next == BatchedClaimMilestoneStatus.cancelled
            case .completed:
                return next == BatchedClaimMilestoneStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedClaimMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched claim milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("batched claim milestone") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(createdAt) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedClaimMilestone {
            return BatchedClaimMilestone(
                code: code,
                title: title,
                createdAt: createdAt,
                visitMinutes: visitMinutes,
                unit: unit,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a batched claim milestone in status planned.
    static func newBatchedClaimMilestone(_ code: String, title: String) -> BatchedClaimMilestone {
        return BatchedClaimMilestone(
            code: code,
            title: title,
            createdAt: 0,
            visitMinutes: 0,
            unit: "",
            active: false,
            status: BatchedClaimMilestoneStatus.planned
        )
    }
}
