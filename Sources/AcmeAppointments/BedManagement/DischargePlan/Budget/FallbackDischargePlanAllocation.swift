import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback discharge plan allocation is in its life cycle.
    enum FallbackDischargePlanAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A fallback discharge plan allocation. Its code is unique within a tenant.
    final class FallbackDischargePlanAllocation {
        var code: String
        var label: String
        var discount: Double
        var notes: String
        var minimum: Double
        var approved: Bool
        var reviewer: String
        var status: FallbackDischargePlanAllocationStatus

        init(code: String, label: String, discount: Double, notes: String, minimum: Double, approved: Bool, reviewer: String, status: FallbackDischargePlanAllocationStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.notes = notes
            self.minimum = minimum
            self.approved = approved
            self.reviewer = reviewer
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

        func canMoveTo(_ next: FallbackDischargePlanAllocationStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == FallbackDischargePlanAllocationStatus.suspended || next == FallbackDischargePlanAllocationStatus.closed
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

        func moveTo(_ next: FallbackDischargePlanAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback discharge plan allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback discharge plan allocation") \(code)"
        }

        func projectedTotal() -> Double {
            return (discount * minimum * 100).rounded() / 100
        }

        func copyValue() -> FallbackDischargePlanAllocation {
            return FallbackDischargePlanAllocation(
                code: code,
                label: label,
                discount: discount,
                notes: notes,
                minimum: minimum,
                approved: approved,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback discharge plan allocation in status draft.
    static func newFallbackDischargePlanAllocation(_ code: String, label: String) -> FallbackDischargePlanAllocation {
        return FallbackDischargePlanAllocation(
            code: code,
            label: label,
            discount: 0.0,
            notes: "",
            minimum: 0.0,
            approved: false,
            reviewer: "",
            status: FallbackDischargePlanAllocationStatus.draft
        )
    }
}
