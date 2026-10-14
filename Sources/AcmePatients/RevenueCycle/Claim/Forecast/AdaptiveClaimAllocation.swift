import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive claim allocation is in its life cycle.
    enum AdaptiveClaimAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive claim allocation. Its code is unique within a tenant.
    final class AdaptiveClaimAllocation {
        var code: String
        var name: String
        var ceiling: Double
        var attempts: Int
        var minimum: Double
        var graceDays: Int
        var expiresAt: Int
        var procedureCode: String
        var status: AdaptiveClaimAllocationStatus

        init(code: String, name: String, ceiling: Double, attempts: Int, minimum: Double, graceDays: Int, expiresAt: Int, procedureCode: String, status: AdaptiveClaimAllocationStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.attempts = attempts
            self.minimum = minimum
            self.graceDays = graceDays
            self.expiresAt = expiresAt
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveClaimAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AdaptiveClaimAllocationStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AdaptiveClaimAllocationStatus.reopened || next == AdaptiveClaimAllocationStatus.archived
            case .reopened:
                return next == AdaptiveClaimAllocationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveClaimAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive claim allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive claim allocation") \(code)"
        }

        func netLoad() -> Double {
            return (Double(graceDays) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveClaimAllocation {
            return AdaptiveClaimAllocation(
                code: code,
                name: name,
                ceiling: ceiling,
                attempts: attempts,
                minimum: minimum,
                graceDays: graceDays,
                expiresAt: expiresAt,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive claim allocation in status open.
    static func newAdaptiveClaimAllocation(_ code: String, name: String) -> AdaptiveClaimAllocation {
        return AdaptiveClaimAllocation(
            code: code,
            name: name,
            ceiling: 0.0,
            attempts: 0,
            minimum: 0.0,
            graceDays: 0,
            expiresAt: 0,
            procedureCode: "",
            status: AdaptiveClaimAllocationStatus.`open`
        )
    }
}
