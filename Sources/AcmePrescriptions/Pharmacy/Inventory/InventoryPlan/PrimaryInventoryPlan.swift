import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary inventory plan is in its life cycle.
    enum PrimaryInventoryPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One primary inventory plan, with what the planners need to act on it.
    final class PrimaryInventoryPlan {
        var code: String
        var title: String
        var weight: Double
        var currency: String
        var phone: String
        var updatedAt: Int
        var priority: Int
        var unit: String
        var version: Int
        var copay: Double
        var status: PrimaryInventoryPlanStatus

        init(code: String, title: String, weight: Double, currency: String, phone: String, updatedAt: Int, priority: Int, unit: String, version: Int, copay: Double, status: PrimaryInventoryPlanStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.currency = currency
            self.phone = phone
            self.updatedAt = updatedAt
            self.priority = priority
            self.unit = unit
            self.version = version
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

        func canMoveTo(_ next: PrimaryInventoryPlanStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PrimaryInventoryPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary inventory plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedTotal() -> Double {
            return (Double(priority) * copay * 100).rounded() / 100
        }

        func copyValue() -> PrimaryInventoryPlan {
            return PrimaryInventoryPlan(
                code: code,
                title: title,
                weight: weight,
                currency: currency,
                phone: phone,
                updatedAt: updatedAt,
                priority: priority,
                unit: unit,
                version: version,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a primary inventory plan in status proposed.
    static func newPrimaryInventoryPlan(_ code: String, title: String) -> PrimaryInventoryPlan {
        return PrimaryInventoryPlan(
            code: code,
            title: title,
            weight: 0.0,
            currency: "",
            phone: "",
            updatedAt: 0,
            priority: 0,
            unit: "",
            version: 0,
            copay: 0.0,
            status: PrimaryInventoryPlanStatus.proposed
        )
    }
}
