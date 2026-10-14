import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory policy is in its life cycle.
    enum InventoryPolicyStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A inventory policy as the inventory team keeps it.
    final class InventoryPolicy {
        var code: String
        var name: String
        var timezone: String
        var durationMinutes: Int
        var checksum: String
        var discount: Double
        var reviewer: String
        var budget: Double
        var archived: Bool
        var bed: String
        var channel: String
        var status: InventoryPolicyStatus

        init(code: String, name: String, timezone: String, durationMinutes: Int, checksum: String, discount: Double, reviewer: String, budget: Double, archived: Bool, bed: String, channel: String, status: InventoryPolicyStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.durationMinutes = durationMinutes
            self.checksum = checksum
            self.discount = discount
            self.reviewer = reviewer
            self.budget = budget
            self.archived = archived
            self.bed = bed
            self.channel = channel
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

        func canMoveTo(_ next: InventoryPolicyStatus) -> Bool {
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
                return next == InventoryPolicyStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == InventoryPolicyStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("inventory policy") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((budget + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> InventoryPolicy {
            return InventoryPolicy(
                code: code,
                name: name,
                timezone: timezone,
                durationMinutes: durationMinutes,
                checksum: checksum,
                discount: discount,
                reviewer: reviewer,
                budget: budget,
                archived: archived,
                bed: bed,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a inventory policy in status planned.
    static func newInventoryPolicy(_ code: String, name: String) -> InventoryPolicy {
        return InventoryPolicy(
            code: code,
            name: name,
            timezone: "",
            durationMinutes: 0,
            checksum: "",
            discount: 0.0,
            reviewer: "",
            budget: 0.0,
            archived: false,
            bed: "",
            channel: "",
            status: InventoryPolicyStatus.planned
        )
    }
}
