import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending inventory request is in its life cycle.
    enum PendingInventoryRequestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A pending inventory request as the inventory team keeps it.
    final class PendingInventoryRequest {
        var code: String
        var title: String
        var country: String
        var createdAt: Int
        var rate: Double
        var dosageMg: Double
        var discount: Double
        var weight: Double
        var status: PendingInventoryRequestStatus

        init(code: String, title: String, country: String, createdAt: Int, rate: Double, dosageMg: Double, discount: Double, weight: Double, status: PendingInventoryRequestStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.createdAt = createdAt
            self.rate = rate
            self.dosageMg = dosageMg
            self.discount = discount
            self.weight = weight
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

        func canMoveTo(_ next: PendingInventoryRequestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == PendingInventoryRequestStatus.published || next == PendingInventoryRequestStatus.retired
            case .published:
                return next == PendingInventoryRequestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingInventoryRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending inventory request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("pending inventory request") \(code)"
        }

        func projectedValue() -> Double {
            return (weight * discount * 100).rounded() / 100
        }

        func copyValue() -> PendingInventoryRequest {
            return PendingInventoryRequest(
                code: code,
                title: title,
                country: country,
                createdAt: createdAt,
                rate: rate,
                dosageMg: dosageMg,
                discount: discount,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a pending inventory request in status created.
    static func newPendingInventoryRequest(_ code: String, title: String) -> PendingInventoryRequest {
        return PendingInventoryRequest(
            code: code,
            title: title,
            country: "",
            createdAt: 0,
            rate: 0.0,
            dosageMg: 0.0,
            discount: 0.0,
            weight: 0.0,
            status: PendingInventoryRequestStatus.created
        )
    }
}
