import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist quota is in its life cycle.
    enum WorklistQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A worklist quota. Its code is unique within a tenant.
    final class WorklistQuota {
        var code: String
        var title: String
        var createdAt: Int
        var minimum: Double
        var retries: Int
        var amount: Double
        var floorValue: Double
        var quantity: Int
        var currency: String
        var durationMinutes: Int
        var phone: String
        var status: WorklistQuotaStatus

        init(code: String, title: String, createdAt: Int, minimum: Double, retries: Int, amount: Double, floorValue: Double, quantity: Int, currency: String, durationMinutes: Int, phone: String, status: WorklistQuotaStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.minimum = minimum
            self.retries = retries
            self.amount = amount
            self.floorValue = floorValue
            self.quantity = quantity
            self.currency = currency
            self.durationMinutes = durationMinutes
            self.phone = phone
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

        func canMoveTo(_ next: WorklistQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WorklistQuotaStatus.approved || next == WorklistQuotaStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == WorklistQuotaStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("worklist quota") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(retries) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> WorklistQuota {
            return WorklistQuota(
                code: code,
                title: title,
                createdAt: createdAt,
                minimum: minimum,
                retries: retries,
                amount: amount,
                floorValue: floorValue,
                quantity: quantity,
                currency: currency,
                durationMinutes: durationMinutes,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a worklist quota in status proposed.
    static func newWorklistQuota(_ code: String, title: String) -> WorklistQuota {
        return WorklistQuota(
            code: code,
            title: title,
            createdAt: 0,
            minimum: 0.0,
            retries: 0,
            amount: 0.0,
            floorValue: 0.0,
            quantity: 0,
            currency: "",
            durationMinutes: 0,
            phone: "",
            status: WorklistQuotaStatus.proposed
        )
    }
}
