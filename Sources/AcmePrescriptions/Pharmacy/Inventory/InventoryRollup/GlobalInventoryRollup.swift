import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global inventory rollup is in its life cycle.
    enum GlobalInventoryRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A global inventory rollup as the inventory team keeps it.
    final class GlobalInventoryRollup {
        var code: String
        var title: String
        var weight: Double
        var payer: String
        var quantity: Int
        var capacity: Int
        var margin: Double
        var bed: String
        var contactEmail: String
        var unit: String
        var status: GlobalInventoryRollupStatus

        init(code: String, title: String, weight: Double, payer: String, quantity: Int, capacity: Int, margin: Double, bed: String, contactEmail: String, unit: String, status: GlobalInventoryRollupStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.payer = payer
            self.quantity = quantity
            self.capacity = capacity
            self.margin = margin
            self.bed = bed
            self.contactEmail = contactEmail
            self.unit = unit
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

        func canMoveTo(_ next: GlobalInventoryRollupStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == GlobalInventoryRollupStatus.closed
            case .active:
                return next == GlobalInventoryRollupStatus.suspended
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

        func moveTo(_ next: GlobalInventoryRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global inventory rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedTotal() -> Double {
            return ((weight - margin) * 100).rounded() / 100
        }

        func copyValue() -> GlobalInventoryRollup {
            return GlobalInventoryRollup(
                code: code,
                title: title,
                weight: weight,
                payer: payer,
                quantity: quantity,
                capacity: capacity,
                margin: margin,
                bed: bed,
                contactEmail: contactEmail,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global inventory rollup in status draft.
    static func newGlobalInventoryRollup(_ code: String, title: String) -> GlobalInventoryRollup {
        return GlobalInventoryRollup(
            code: code,
            title: title,
            weight: 0.0,
            payer: "",
            quantity: 0,
            capacity: 0,
            margin: 0.0,
            bed: "",
            contactEmail: "",
            unit: "",
            status: GlobalInventoryRollupStatus.draft
        )
    }
}
