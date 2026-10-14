import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory estimate is in its life cycle.
    enum InventoryEstimateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A inventory estimate as the inventory team keeps it.
    final class InventoryEstimate {
        var code: String
        var name: String
        var amount: Double
        var bed: String
        var maximum: Double
        var ward: String
        var visitMinutes: Int
        var specialty: String
        var floorValue: Double
        var retries: Int
        var version: Int
        var status: InventoryEstimateStatus

        init(code: String, name: String, amount: Double, bed: String, maximum: Double, ward: String, visitMinutes: Int, specialty: String, floorValue: Double, retries: Int, version: Int, status: InventoryEstimateStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.bed = bed
            self.maximum = maximum
            self.ward = ward
            self.visitMinutes = visitMinutes
            self.specialty = specialty
            self.floorValue = floorValue
            self.retries = retries
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InventoryEstimateStatus) -> Bool {
            switch status {
            case .draft:
                return next == InventoryEstimateStatus.active || next == InventoryEstimateStatus.suspended
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == InventoryEstimateStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: InventoryEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveLoad() -> Double {
            return ((amount + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> InventoryEstimate {
            return InventoryEstimate(
                code: code,
                name: name,
                amount: amount,
                bed: bed,
                maximum: maximum,
                ward: ward,
                visitMinutes: visitMinutes,
                specialty: specialty,
                floorValue: floorValue,
                retries: retries,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a inventory estimate in status draft.
    static func newInventoryEstimate(_ code: String, name: String) -> InventoryEstimate {
        return InventoryEstimate(
            code: code,
            name: name,
            amount: 0.0,
            bed: "",
            maximum: 0.0,
            ward: "",
            visitMinutes: 0,
            specialty: "",
            floorValue: 0.0,
            retries: 0,
            version: 0,
            status: InventoryEstimateStatus.draft
        )
    }
}
