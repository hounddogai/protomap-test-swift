import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding slot is in its life cycle.
    enum RoundingSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One rounding slot, with what the planners need to act on it.
    final class RoundingSlot {
        var code: String
        var name: String
        var cost: Double
        var patientRef: String
        var active: Bool
        var status: RoundingSlotStatus

        init(code: String, name: String, cost: Double, patientRef: String, active: Bool, status: RoundingSlotStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.patientRef = patientRef
            self.active = active
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

        func canMoveTo(_ next: RoundingSlotStatus) -> Bool {
            switch status {
            case .created:
                return next == RoundingSlotStatus.published || next == RoundingSlotStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RoundingSlotStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rounding slot") \(code)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> RoundingSlot {
            return RoundingSlot(
                code: code,
                name: name,
                cost: cost,
                patientRef: patientRef,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rounding slot in status created.
    static func newRoundingSlot(_ code: String, name: String) -> RoundingSlot {
        return RoundingSlot(
            code: code,
            name: name,
            cost: 0.0,
            patientRef: "",
            active: false,
            status: RoundingSlotStatus.created
        )
    }
}
