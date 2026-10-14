import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending formulary allocation is in its life cycle.
    enum PendingFormularyAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One pending formulary allocation, with what the planners need to act on it.
    final class PendingFormularyAllocation {
        var code: String
        var title: String
        var bed: String
        var pinned: Bool
        var clinicianID: String
        var active: Bool
        var margin: Double
        var status: PendingFormularyAllocationStatus

        init(code: String, title: String, bed: String, pinned: Bool, clinicianID: String, active: Bool, margin: Double, status: PendingFormularyAllocationStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.pinned = pinned
            self.clinicianID = clinicianID
            self.active = active
            self.margin = margin
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

        func canMoveTo(_ next: PendingFormularyAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingFormularyAllocationStatus.approved || next == PendingFormularyAllocationStatus.withdrawn
            case .approved:
                return next == PendingFormularyAllocationStatus.rejected || next == PendingFormularyAllocationStatus.withdrawn
            case .rejected:
                return next == PendingFormularyAllocationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingFormularyAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending formulary allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> PendingFormularyAllocation {
            return PendingFormularyAllocation(
                code: code,
                title: title,
                bed: bed,
                pinned: pinned,
                clinicianID: clinicianID,
                active: active,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending formulary allocation in status proposed.
    static func newPendingFormularyAllocation(_ code: String, title: String) -> PendingFormularyAllocation {
        return PendingFormularyAllocation(
            code: code,
            title: title,
            bed: "",
            pinned: false,
            clinicianID: "",
            active: false,
            margin: 0.0,
            status: PendingFormularyAllocationStatus.proposed
        )
    }
}
