import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive closure forecast is in its life cycle.
    enum AdaptiveClosureForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive closure forecast as the closure team keeps it.
    final class AdaptiveClosureForecast {
        var code: String
        var name: String
        var payer: String
        var visitMinutes: Int
        var weight: Double
        var capacity: Int
        var description: String
        var label: String
        var quantity: Int
        var unit: String
        var amount: Double
        var status: AdaptiveClosureForecastStatus

        init(code: String, name: String, payer: String, visitMinutes: Int, weight: Double, capacity: Int, description: String, label: String, quantity: Int, unit: String, amount: Double, status: AdaptiveClosureForecastStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.visitMinutes = visitMinutes
            self.weight = weight
            self.capacity = capacity
            self.description = description
            self.label = label
            self.quantity = quantity
            self.unit = unit
            self.amount = amount
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

        func canMoveTo(_ next: AdaptiveClosureForecastStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AdaptiveClosureForecastStatus.rejected
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

        func moveTo(_ next: AdaptiveClosureForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive closure forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func netExposure() -> Double {
            return ((Double(visitMinutes) + amount) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveClosureForecast {
            return AdaptiveClosureForecast(
                code: code,
                name: name,
                payer: payer,
                visitMinutes: visitMinutes,
                weight: weight,
                capacity: capacity,
                description: description,
                label: label,
                quantity: quantity,
                unit: unit,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a adaptive closure forecast in status proposed.
    static func newAdaptiveClosureForecast(_ code: String, name: String) -> AdaptiveClosureForecast {
        return AdaptiveClosureForecast(
            code: code,
            name: name,
            payer: "",
            visitMinutes: 0,
            weight: 0.0,
            capacity: 0,
            description: "",
            label: "",
            quantity: 0,
            unit: "",
            amount: 0.0,
            status: AdaptiveClosureForecastStatus.proposed
        )
    }
}
