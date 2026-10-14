import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set quota is in its life cycle.
    enum OrderSetQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A order set quota. Its code is unique within a tenant.
    final class OrderSetQuota {
        var code: String
        var label: String
        var quantity: Int
        var threshold: Double
        var country: String
        var description: String
        var title: String
        var updatedAt: Int
        var channel: String
        var cost: Double
        var allergy: String
        var status: OrderSetQuotaStatus

        init(code: String, label: String, quantity: Int, threshold: Double, country: String, description: String, title: String, updatedAt: Int, channel: String, cost: Double, allergy: String, status: OrderSetQuotaStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.threshold = threshold
            self.country = country
            self.description = description
            self.title = title
            self.updatedAt = updatedAt
            self.channel = channel
            self.cost = cost
            self.allergy = allergy
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

        func canMoveTo(_ next: OrderSetQuotaStatus) -> Bool {
            switch status {
            case .created:
                return next == OrderSetQuotaStatus.published || next == OrderSetQuotaStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == OrderSetQuotaStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netExposure() -> Double {
            return ((threshold + cost) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetQuota {
            return OrderSetQuota(
                code: code,
                label: label,
                quantity: quantity,
                threshold: threshold,
                country: country,
                description: description,
                title: title,
                updatedAt: updatedAt,
                channel: channel,
                cost: cost,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a order set quota in status created.
    static func newOrderSetQuota(_ code: String, label: String) -> OrderSetQuota {
        return OrderSetQuota(
            code: code,
            label: label,
            quantity: 0,
            threshold: 0.0,
            country: "",
            description: "",
            title: "",
            updatedAt: 0,
            channel: "",
            cost: 0.0,
            allergy: "",
            status: OrderSetQuotaStatus.created
        )
    }
}
