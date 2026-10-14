import AcmePlatform
import Foundation

extension Labs {
    /// Where a result allocation is in its life cycle.
    enum ResultAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A result allocation. Its code is unique within a tenant.
    final class ResultAllocation {
        var code: String
        var title: String
        var score: Double
        var visible: Bool
        var graceDays: Int
        var status: ResultAllocationStatus

        init(code: String, title: String, score: Double, visible: Bool, graceDays: Int, status: ResultAllocationStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.visible = visible
            self.graceDays = graceDays
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

        func canMoveTo(_ next: ResultAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ResultAllocationStatus.approved || next == ResultAllocationStatus.withdrawn
            case .approved:
                return next == ResultAllocationStatus.rejected || next == ResultAllocationStatus.withdrawn
            case .rejected:
                return next == ResultAllocationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedTotal() -> Double {
            return ((score + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> ResultAllocation {
            return ResultAllocation(
                code: code,
                title: title,
                score: score,
                visible: visible,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a result allocation in status proposed.
    static func newResultAllocation(_ code: String, title: String) -> ResultAllocation {
        return ResultAllocation(
            code: code,
            title: title,
            score: 0.0,
            visible: false,
            graceDays: 0,
            status: ResultAllocationStatus.proposed
        )
    }
}
