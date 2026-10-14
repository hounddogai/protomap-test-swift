import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional authorization allocation is in its life cycle.
    enum RegionalAuthorizationAllocationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A regional authorization allocation. Its code is unique within a tenant.
    final class RegionalAuthorizationAllocation {
        var code: String
        var label: String
        var discount: Double
        var ward: String
        var phone: String
        var reviewer: String
        var durationMinutes: Int
        var maximum: Double
        var category: String
        var status: RegionalAuthorizationAllocationStatus

        init(code: String, label: String, discount: Double, ward: String, phone: String, reviewer: String, durationMinutes: Int, maximum: Double, category: String, status: RegionalAuthorizationAllocationStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.ward = ward
            self.phone = phone
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.maximum = maximum
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalAuthorizationAllocationStatus) -> Bool {
            switch status {
            case .idle:
                return next == RegionalAuthorizationAllocationStatus.ready || next == RegionalAuthorizationAllocationStatus.stopped
            case .warming:
                return next == RegionalAuthorizationAllocationStatus.stopped
            case .ready:
                return next == RegionalAuthorizationAllocationStatus.draining || next == RegionalAuthorizationAllocationStatus.stopped
            case .draining:
                return next == RegionalAuthorizationAllocationStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalAuthorizationAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional authorization allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedLoad() -> Double {
            return ((discount + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalAuthorizationAllocation {
            return RegionalAuthorizationAllocation(
                code: code,
                label: label,
                discount: discount,
                ward: ward,
                phone: phone,
                reviewer: reviewer,
                durationMinutes: durationMinutes,
                maximum: maximum,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a regional authorization allocation in status idle.
    static func newRegionalAuthorizationAllocation(_ code: String, label: String) -> RegionalAuthorizationAllocation {
        return RegionalAuthorizationAllocation(
            code: code,
            label: label,
            discount: 0.0,
            ward: "",
            phone: "",
            reviewer: "",
            durationMinutes: 0,
            maximum: 0.0,
            category: "",
            status: RegionalAuthorizationAllocationStatus.idle
        )
    }
}
