import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory checkpoint is in its life cycle.
    enum InventoryCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A inventory checkpoint as the inventory team keeps it.
    final class InventoryCheckpoint {
        var code: String
        var name: String
        var graceDays: Int
        var ratio: Double
        var rate: Double
        var currency: String
        var updatedAt: Int
        var cost: Double
        var acuity: Int
        var checksum: String
        var status: InventoryCheckpointStatus

        init(code: String, name: String, graceDays: Int, ratio: Double, rate: Double, currency: String, updatedAt: Int, cost: Double, acuity: Int, checksum: String, status: InventoryCheckpointStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.ratio = ratio
            self.rate = rate
            self.currency = currency
            self.updatedAt = updatedAt
            self.cost = cost
            self.acuity = acuity
            self.checksum = checksum
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

        func canMoveTo(_ next: InventoryCheckpointStatus) -> Bool {
            switch status {
            case .`open`:
                return next == InventoryCheckpointStatus.resolved || next == InventoryCheckpointStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == InventoryCheckpointStatus.reopened || next == InventoryCheckpointStatus.archived
            case .reopened:
                return next == InventoryCheckpointStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netLoad() -> Double {
            return ((ratio + cost) * 100).rounded() / 100
        }

        func copyValue() -> InventoryCheckpoint {
            return InventoryCheckpoint(
                code: code,
                name: name,
                graceDays: graceDays,
                ratio: ratio,
                rate: rate,
                currency: currency,
                updatedAt: updatedAt,
                cost: cost,
                acuity: acuity,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a inventory checkpoint in status open.
    static func newInventoryCheckpoint(_ code: String, name: String) -> InventoryCheckpoint {
        return InventoryCheckpoint(
            code: code,
            name: name,
            graceDays: 0,
            ratio: 0.0,
            rate: 0.0,
            currency: "",
            updatedAt: 0,
            cost: 0.0,
            acuity: 0,
            checksum: "",
            status: InventoryCheckpointStatus.`open`
        )
    }
}
