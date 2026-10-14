import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial claim is in its life cycle.
    enum DenialClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a denial claim and its current status.
    final class DenialClaim {
        var code: String
        var label: String
        var category: String
        var amount: Double
        var graceDays: Int
        var checksum: String
        var unit: String
        var ceiling: Double
        var priority: Int
        var status: DenialClaimStatus

        init(code: String, label: String, category: String, amount: Double, graceDays: Int, checksum: String, unit: String, ceiling: Double, priority: Int, status: DenialClaimStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.amount = amount
            self.graceDays = graceDays
            self.checksum = checksum
            self.unit = unit
            self.ceiling = ceiling
            self.priority = priority
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

        func canMoveTo(_ next: DenialClaimStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DenialClaimStatus.rejected
            case .approved:
                return next == DenialClaimStatus.withdrawn
            case .rejected:
                return next == DenialClaimStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveVolume() -> Double {
            return ((Double(graceDays) - amount) * 100).rounded() / 100
        }

        func copyValue() -> DenialClaim {
            return DenialClaim(
                code: code,
                label: label,
                category: category,
                amount: amount,
                graceDays: graceDays,
                checksum: checksum,
                unit: unit,
                ceiling: ceiling,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a denial claim in status proposed.
    static func newDenialClaim(_ code: String, label: String) -> DenialClaim {
        return DenialClaim(
            code: code,
            label: label,
            category: "",
            amount: 0.0,
            graceDays: 0,
            checksum: "",
            unit: "",
            ceiling: 0.0,
            priority: 0,
            status: DenialClaimStatus.proposed
        )
    }
}
