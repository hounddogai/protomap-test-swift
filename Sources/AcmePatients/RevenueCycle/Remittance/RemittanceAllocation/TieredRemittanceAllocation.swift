import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered remittance allocation is in its life cycle.
    enum TieredRemittanceAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One tiered remittance allocation, with what the planners need to act on it.
    final class TieredRemittanceAllocation {
        var code: String
        var label: String
        var checksum: String
        var capacity: Int
        var category: String
        var startsAt: Int
        var region: String
        var cost: Double
        var status: TieredRemittanceAllocationStatus

        init(code: String, label: String, checksum: String, capacity: Int, category: String, startsAt: Int, region: String, cost: Double, status: TieredRemittanceAllocationStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.capacity = capacity
            self.category = category
            self.startsAt = startsAt
            self.region = region
            self.cost = cost
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

        func canMoveTo(_ next: TieredRemittanceAllocationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == TieredRemittanceAllocationStatus.inProgress || next == TieredRemittanceAllocationStatus.completed
            case .inProgress:
                return next == TieredRemittanceAllocationStatus.cancelled
            case .completed:
                return next == TieredRemittanceAllocationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRemittanceAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered remittance allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedLoad() -> Double {
            return (Double(capacity) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> TieredRemittanceAllocation {
            return TieredRemittanceAllocation(
                code: code,
                label: label,
                checksum: checksum,
                capacity: capacity,
                category: category,
                startsAt: startsAt,
                region: region,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered remittance allocation in status planned.
    static func newTieredRemittanceAllocation(_ code: String, label: String) -> TieredRemittanceAllocation {
        return TieredRemittanceAllocation(
            code: code,
            label: label,
            checksum: "",
            capacity: 0,
            category: "",
            startsAt: 0,
            region: "",
            cost: 0.0,
            status: TieredRemittanceAllocationStatus.planned
        )
    }
}
