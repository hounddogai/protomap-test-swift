import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched revocation target is in its life cycle.
    enum BatchedRevocationTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A batched revocation target as the revocation team keeps it.
    final class BatchedRevocationTarget {
        var code: String
        var name: String
        var discount: Double
        var cost: Double
        var label: String
        var version: Int
        var quantity: Int
        var category: String
        var windowDays: Int
        var endsAt: Int
        var status: BatchedRevocationTargetStatus

        init(code: String, name: String, discount: Double, cost: Double, label: String, version: Int, quantity: Int, category: String, windowDays: Int, endsAt: Int, status: BatchedRevocationTargetStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.cost = cost
            self.label = label
            self.version = version
            self.quantity = quantity
            self.category = category
            self.windowDays = windowDays
            self.endsAt = endsAt
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

        func canMoveTo(_ next: BatchedRevocationTargetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == BatchedRevocationTargetStatus.withdrawn
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

        func moveTo(_ next: BatchedRevocationTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched revocation target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func effectiveVolume() -> Double {
            return ((Double(version) - discount) * 100).rounded() / 100
        }

        func copyValue() -> BatchedRevocationTarget {
            return BatchedRevocationTarget(
                code: code,
                name: name,
                discount: discount,
                cost: cost,
                label: label,
                version: version,
                quantity: quantity,
                category: category,
                windowDays: windowDays,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched revocation target in status proposed.
    static func newBatchedRevocationTarget(_ code: String, name: String) -> BatchedRevocationTarget {
        return BatchedRevocationTarget(
            code: code,
            name: name,
            discount: 0.0,
            cost: 0.0,
            label: "",
            version: 0,
            quantity: 0,
            category: "",
            windowDays: 0,
            endsAt: 0,
            status: BatchedRevocationTargetStatus.proposed
        )
    }
}
