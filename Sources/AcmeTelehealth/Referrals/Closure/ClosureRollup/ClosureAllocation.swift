import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure allocation is in its life cycle.
    enum ClosureAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A closure allocation as the closure team keeps it.
    final class ClosureAllocation {
        var code: String
        var label: String
        var retries: Int
        var ceiling: Double
        var locale: String
        var status: ClosureAllocationStatus

        init(code: String, label: String, retries: Int, ceiling: Double, locale: String, status: ClosureAllocationStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.ceiling = ceiling
            self.locale = locale
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

        func canMoveTo(_ next: ClosureAllocationStatus) -> Bool {
            switch status {
            case .draft:
                return next == ClosureAllocationStatus.active
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ClosureAllocationStatus.suspended || next == ClosureAllocationStatus.closed
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

        func moveTo(_ next: ClosureAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netLoad() -> Double {
            return (Double(retries) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> ClosureAllocation {
            return ClosureAllocation(
                code: code,
                label: label,
                retries: retries,
                ceiling: ceiling,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a closure allocation in status draft.
    static func newClosureAllocation(_ code: String, label: String) -> ClosureAllocation {
        return ClosureAllocation(
            code: code,
            label: label,
            retries: 0,
            ceiling: 0.0,
            locale: "",
            status: ClosureAllocationStatus.draft
        )
    }
}
