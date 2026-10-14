import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending substitution allocation is in its life cycle.
    enum PendingSubstitutionAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a pending substitution allocation and its current status.
    final class PendingSubstitutionAllocation {
        var code: String
        var title: String
        var active: Bool
        var version: Int
        var approved: Bool
        var windowDays: Int
        var amount: Double
        var refills: Int
        var capacity: Int
        var copay: Double
        var status: PendingSubstitutionAllocationStatus

        init(code: String, title: String, active: Bool, version: Int, approved: Bool, windowDays: Int, amount: Double, refills: Int, capacity: Int, copay: Double, status: PendingSubstitutionAllocationStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.version = version
            self.approved = approved
            self.windowDays = windowDays
            self.amount = amount
            self.refills = refills
            self.capacity = capacity
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

        func canMoveTo(_ next: PendingSubstitutionAllocationStatus) -> Bool {
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
                return next == PendingSubstitutionAllocationStatus.suspended || next == PendingSubstitutionAllocationStatus.closed
            case .active:
                return next == PendingSubstitutionAllocationStatus.closed
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

        func moveTo(_ next: PendingSubstitutionAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending substitution allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("pending substitution allocation") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((copay + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> PendingSubstitutionAllocation {
            return PendingSubstitutionAllocation(
                code: code,
                title: title,
                active: active,
                version: version,
                approved: approved,
                windowDays: windowDays,
                amount: amount,
                refills: refills,
                capacity: capacity,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending substitution allocation in status draft.
    static func newPendingSubstitutionAllocation(_ code: String, title: String) -> PendingSubstitutionAllocation {
        return PendingSubstitutionAllocation(
            code: code,
            title: title,
            active: false,
            version: 0,
            approved: false,
            windowDays: 0,
            amount: 0.0,
            refills: 0,
            capacity: 0,
            copay: 0.0,
            status: PendingSubstitutionAllocationStatus.draft
        )
    }
}
