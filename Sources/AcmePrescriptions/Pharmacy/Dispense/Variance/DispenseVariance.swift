import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense variance is in its life cycle.
    enum DispenseVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A dispense variance as the dispense team keeps it.
    final class DispenseVariance {
        var code: String
        var name: String
        var dosageMg: Double
        var floorValue: Double
        var phone: String
        var active: Bool
        var quantity: Int
        var weight: Double
        var rate: Double
        var approved: Bool
        var status: DispenseVarianceStatus

        init(code: String, name: String, dosageMg: Double, floorValue: Double, phone: String, active: Bool, quantity: Int, weight: Double, rate: Double, approved: Bool, status: DispenseVarianceStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.floorValue = floorValue
            self.phone = phone
            self.active = active
            self.quantity = quantity
            self.weight = weight
            self.rate = rate
            self.approved = approved
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

        func canMoveTo(_ next: DispenseVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DispenseVarianceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("dispense variance") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((rate - weight) * 100).rounded() / 100
        }

        func copyValue() -> DispenseVariance {
            return DispenseVariance(
                code: code,
                name: name,
                dosageMg: dosageMg,
                floorValue: floorValue,
                phone: phone,
                active: active,
                quantity: quantity,
                weight: weight,
                rate: rate,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a dispense variance in status proposed.
    static func newDispenseVariance(_ code: String, name: String) -> DispenseVariance {
        return DispenseVariance(
            code: code,
            name: name,
            dosageMg: 0.0,
            floorValue: 0.0,
            phone: "",
            active: false,
            quantity: 0,
            weight: 0.0,
            rate: 0.0,
            approved: false,
            status: DispenseVarianceStatus.proposed
        )
    }
}
