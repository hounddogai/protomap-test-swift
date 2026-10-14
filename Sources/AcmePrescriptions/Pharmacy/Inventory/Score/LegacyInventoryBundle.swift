import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy inventory bundle is in its life cycle.
    enum LegacyInventoryBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a legacy inventory bundle and its current status.
    final class LegacyInventoryBundle {
        var code: String
        var label: String
        var amount: Double
        var allergy: String
        var unit: String
        var cost: Double
        var capacity: Int
        var status: LegacyInventoryBundleStatus

        init(code: String, label: String, amount: Double, allergy: String, unit: String, cost: Double, capacity: Int, status: LegacyInventoryBundleStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.allergy = allergy
            self.unit = unit
            self.cost = cost
            self.capacity = capacity
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

        func canMoveTo(_ next: LegacyInventoryBundleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LegacyInventoryBundleStatus.approved || next == LegacyInventoryBundleStatus.rejected
            case .approved:
                return next == LegacyInventoryBundleStatus.rejected || next == LegacyInventoryBundleStatus.withdrawn
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

        func moveTo(_ next: LegacyInventoryBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy inventory bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return ((cost + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyInventoryBundle {
            return LegacyInventoryBundle(
                code: code,
                label: label,
                amount: amount,
                allergy: allergy,
                unit: unit,
                cost: cost,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy inventory bundle in status proposed.
    static func newLegacyInventoryBundle(_ code: String, label: String) -> LegacyInventoryBundle {
        return LegacyInventoryBundle(
            code: code,
            label: label,
            amount: 0.0,
            allergy: "",
            unit: "",
            cost: 0.0,
            capacity: 0,
            status: LegacyInventoryBundleStatus.proposed
        )
    }
}
