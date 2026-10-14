import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling result threshold is in its life cycle.
    enum RollingResultThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rolling result threshold. Its code is unique within a tenant.
    final class RollingResultThreshold {
        var code: String
        var name: String
        var timezone: String
        var floorValue: Double
        var bed: String
        var quantity: Int
        var encounterID: String
        var copay: Double
        var status: RollingResultThresholdStatus

        init(code: String, name: String, timezone: String, floorValue: Double, bed: String, quantity: Int, encounterID: String, copay: Double, status: RollingResultThresholdStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.floorValue = floorValue
            self.bed = bed
            self.quantity = quantity
            self.encounterID = encounterID
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingResultThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RollingResultThresholdStatus.approved || next == RollingResultThresholdStatus.rejected
            case .approved:
                return next == RollingResultThresholdStatus.rejected || next == RollingResultThresholdStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RollingResultThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling result threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedTotal() -> Double {
            return (floorValue * copay * 100).rounded() / 100
        }

        func copyValue() -> RollingResultThreshold {
            return RollingResultThreshold(
                code: code,
                name: name,
                timezone: timezone,
                floorValue: floorValue,
                bed: bed,
                quantity: quantity,
                encounterID: encounterID,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling result threshold in status proposed.
    static func newRollingResultThreshold(_ code: String, name: String) -> RollingResultThreshold {
        return RollingResultThreshold(
            code: code,
            name: name,
            timezone: "",
            floorValue: 0.0,
            bed: "",
            quantity: 0,
            encounterID: "",
            copay: 0.0,
            status: RollingResultThresholdStatus.proposed
        )
    }
}
