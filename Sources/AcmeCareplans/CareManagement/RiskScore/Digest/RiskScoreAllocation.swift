import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score allocation is in its life cycle.
    enum RiskScoreAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A risk score allocation as the risk score team keeps it.
    final class RiskScoreAllocation {
        var code: String
        var title: String
        var active: Bool
        var pinned: Bool
        var ward: String
        var copay: Double
        var status: RiskScoreAllocationStatus

        init(code: String, title: String, active: Bool, pinned: Bool, ward: String, copay: Double, status: RiskScoreAllocationStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.pinned = pinned
            self.ward = ward
            self.copay = copay
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

        func canMoveTo(_ next: RiskScoreAllocationStatus) -> Bool {
            switch status {
            case .draft:
                return next == RiskScoreAllocationStatus.pending || next == RiskScoreAllocationStatus.closed
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == RiskScoreAllocationStatus.closed
            case .suspended:
                return next == RiskScoreAllocationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> RiskScoreAllocation {
            return RiskScoreAllocation(
                code: code,
                title: title,
                active: active,
                pinned: pinned,
                ward: ward,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a risk score allocation in status draft.
    static func newRiskScoreAllocation(_ code: String, title: String) -> RiskScoreAllocation {
        return RiskScoreAllocation(
            code: code,
            title: title,
            active: false,
            pinned: false,
            ward: "",
            copay: 0.0,
            status: RiskScoreAllocationStatus.draft
        )
    }
}
