import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary order set cycle is in its life cycle.
    enum PrimaryOrderSetCycleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One primary order set cycle, with what the planners need to act on it.
    final class PrimaryOrderSetCycle {
        var code: String
        var label: String
        var floorValue: Double
        var ownerID: String
        var quantity: Int
        var encounterID: String
        var ceiling: Double
        var priority: Int
        var maximum: Double
        var segment: String
        var durationMinutes: Int
        var status: PrimaryOrderSetCycleStatus

        init(code: String, label: String, floorValue: Double, ownerID: String, quantity: Int, encounterID: String, ceiling: Double, priority: Int, maximum: Double, segment: String, durationMinutes: Int, status: PrimaryOrderSetCycleStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.ownerID = ownerID
            self.quantity = quantity
            self.encounterID = encounterID
            self.ceiling = ceiling
            self.priority = priority
            self.maximum = maximum
            self.segment = segment
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryOrderSetCycleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == PrimaryOrderSetCycleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryOrderSetCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary order set cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedLoad() -> Double {
            return (ceiling * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryOrderSetCycle {
            return PrimaryOrderSetCycle(
                code: code,
                label: label,
                floorValue: floorValue,
                ownerID: ownerID,
                quantity: quantity,
                encounterID: encounterID,
                ceiling: ceiling,
                priority: priority,
                maximum: maximum,
                segment: segment,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a primary order set cycle in status requested.
    static func newPrimaryOrderSetCycle(_ code: String, label: String) -> PrimaryOrderSetCycle {
        return PrimaryOrderSetCycle(
            code: code,
            label: label,
            floorValue: 0.0,
            ownerID: "",
            quantity: 0,
            encounterID: "",
            ceiling: 0.0,
            priority: 0,
            maximum: 0.0,
            segment: "",
            durationMinutes: 0,
            status: PrimaryOrderSetCycleStatus.requested
        )
    }
}
