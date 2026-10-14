import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global shift allocation is in its life cycle.
    enum GlobalShiftAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A global shift allocation as the shift team keeps it.
    final class GlobalShiftAllocation {
        var code: String
        var title: String
        var category: String
        var revision: Int
        var budget: Double
        var status: GlobalShiftAllocationStatus

        init(code: String, title: String, category: String, revision: Int, budget: Double, status: GlobalShiftAllocationStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.revision = revision
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalShiftAllocationStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalShiftAllocationStatus.revoked
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: GlobalShiftAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global shift allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedVolume() -> Double {
            return ((budget + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalShiftAllocation {
            return GlobalShiftAllocation(
                code: code,
                title: title,
                category: category,
                revision: revision,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a global shift allocation in status requested.
    static func newGlobalShiftAllocation(_ code: String, title: String) -> GlobalShiftAllocation {
        return GlobalShiftAllocation(
            code: code,
            title: title,
            category: "",
            revision: 0,
            budget: 0.0,
            status: GlobalShiftAllocationStatus.requested
        )
    }
}
