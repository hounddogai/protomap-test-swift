import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim allocation is in its life cycle.
    enum ClaimAllocationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a claim allocation and its current status.
    final class ClaimAllocation {
        var code: String
        var name: String
        var approved: Bool
        var reviewer: String
        var acuity: Int
        var ratio: Double
        var margin: Double
        var status: ClaimAllocationStatus

        init(code: String, name: String, approved: Bool, reviewer: String, acuity: Int, ratio: Double, margin: Double, status: ClaimAllocationStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.reviewer = reviewer
            self.acuity = acuity
            self.ratio = ratio
            self.margin = margin
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

        func canMoveTo(_ next: ClaimAllocationStatus) -> Bool {
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
                return next == ClaimAllocationStatus.published || next == ClaimAllocationStatus.retired
            case .published:
                return next == ClaimAllocationStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedValue() -> Double {
            return ((Double(acuity) + margin) * 100).rounded() / 100
        }

        func copyValue() -> ClaimAllocation {
            return ClaimAllocation(
                code: code,
                name: name,
                approved: approved,
                reviewer: reviewer,
                acuity: acuity,
                ratio: ratio,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a claim allocation in status created.
    static func newClaimAllocation(_ code: String, name: String) -> ClaimAllocation {
        return ClaimAllocation(
            code: code,
            name: name,
            approved: false,
            reviewer: "",
            acuity: 0,
            ratio: 0.0,
            margin: 0.0,
            status: ClaimAllocationStatus.created
        )
    }
}
