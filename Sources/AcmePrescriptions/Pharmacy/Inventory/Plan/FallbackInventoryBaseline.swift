import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback inventory baseline is in its life cycle.
    enum FallbackInventoryBaselineStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback inventory baseline as the inventory team keeps it.
    final class FallbackInventoryBaseline {
        var code: String
        var name: String
        var procedureCode: String
        var currency: String
        var encounterID: String
        var priority: Int
        var category: String
        var discount: Double
        var status: FallbackInventoryBaselineStatus

        init(code: String, name: String, procedureCode: String, currency: String, encounterID: String, priority: Int, category: String, discount: Double, status: FallbackInventoryBaselineStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.currency = currency
            self.encounterID = encounterID
            self.priority = priority
            self.category = category
            self.discount = discount
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

        func canMoveTo(_ next: FallbackInventoryBaselineStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackInventoryBaselineStatus.granted || next == FallbackInventoryBaselineStatus.revoked
            case .granted:
                return next == FallbackInventoryBaselineStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: FallbackInventoryBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback inventory baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback inventory baseline") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((discount + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackInventoryBaseline {
            return FallbackInventoryBaseline(
                code: code,
                name: name,
                procedureCode: procedureCode,
                currency: currency,
                encounterID: encounterID,
                priority: priority,
                category: category,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a fallback inventory baseline in status requested.
    static func newFallbackInventoryBaseline(_ code: String, name: String) -> FallbackInventoryBaseline {
        return FallbackInventoryBaseline(
            code: code,
            name: name,
            procedureCode: "",
            currency: "",
            encounterID: "",
            priority: 0,
            category: "",
            discount: 0.0,
            status: FallbackInventoryBaselineStatus.requested
        )
    }
}
