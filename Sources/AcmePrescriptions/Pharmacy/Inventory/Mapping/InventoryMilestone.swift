import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory milestone is in its life cycle.
    enum InventoryMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A inventory milestone. Its code is unique within a tenant.
    final class InventoryMilestone {
        var code: String
        var name: String
        var ratio: Double
        var durationMinutes: Int
        var rate: Double
        var allergy: String
        var source: String
        var checksum: String
        var status: InventoryMilestoneStatus

        init(code: String, name: String, ratio: Double, durationMinutes: Int, rate: Double, allergy: String, source: String, checksum: String, status: InventoryMilestoneStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.durationMinutes = durationMinutes
            self.rate = rate
            self.allergy = allergy
            self.source = source
            self.checksum = checksum
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

        func canMoveTo(_ next: InventoryMilestoneStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == InventoryMilestoneStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: InventoryMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netVolume() -> Double {
            return ((Double(durationMinutes) + rate) * 100).rounded() / 100
        }

        func copyValue() -> InventoryMilestone {
            return InventoryMilestone(
                code: code,
                name: name,
                ratio: ratio,
                durationMinutes: durationMinutes,
                rate: rate,
                allergy: allergy,
                source: source,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a inventory milestone in status planned.
    static func newInventoryMilestone(_ code: String, name: String) -> InventoryMilestone {
        return InventoryMilestone(
            code: code,
            name: name,
            ratio: 0.0,
            durationMinutes: 0,
            rate: 0.0,
            allergy: "",
            source: "",
            checksum: "",
            status: InventoryMilestoneStatus.planned
        )
    }
}
