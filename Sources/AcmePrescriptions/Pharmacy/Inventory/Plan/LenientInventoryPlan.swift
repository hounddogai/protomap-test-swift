import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient inventory plan is in its life cycle.
    enum LenientInventoryPlanStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A lenient inventory plan. Its code is unique within a tenant.
    final class LenientInventoryPlan {
        var code: String
        var label: String
        var acuity: Int
        var windowDays: Int
        var capacity: Int
        var allergy: String
        var createdAt: Int
        var graceDays: Int
        var currency: String
        var retries: Int
        var status: LenientInventoryPlanStatus

        init(code: String, label: String, acuity: Int, windowDays: Int, capacity: Int, allergy: String, createdAt: Int, graceDays: Int, currency: String, retries: Int, status: LenientInventoryPlanStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.windowDays = windowDays
            self.capacity = capacity
            self.allergy = allergy
            self.createdAt = createdAt
            self.graceDays = graceDays
            self.currency = currency
            self.retries = retries
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

        func canMoveTo(_ next: LenientInventoryPlanStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == LenientInventoryPlanStatus.published || next == LenientInventoryPlanStatus.retired
            case .published:
                return next == LenientInventoryPlanStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientInventoryPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient inventory plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedExposure() -> Double {
            return ((Double(createdAt) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> LenientInventoryPlan {
            return LenientInventoryPlan(
                code: code,
                label: label,
                acuity: acuity,
                windowDays: windowDays,
                capacity: capacity,
                allergy: allergy,
                createdAt: createdAt,
                graceDays: graceDays,
                currency: currency,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient inventory plan in status created.
    static func newLenientInventoryPlan(_ code: String, label: String) -> LenientInventoryPlan {
        return LenientInventoryPlan(
            code: code,
            label: label,
            acuity: 0,
            windowDays: 0,
            capacity: 0,
            allergy: "",
            createdAt: 0,
            graceDays: 0,
            currency: "",
            retries: 0,
            status: LenientInventoryPlanStatus.created
        )
    }
}
