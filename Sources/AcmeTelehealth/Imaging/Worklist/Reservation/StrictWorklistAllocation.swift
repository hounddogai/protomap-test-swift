import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict worklist allocation is in its life cycle.
    enum StrictWorklistAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One strict worklist allocation, with what the planners need to act on it.
    final class StrictWorklistAllocation {
        var code: String
        var name: String
        var pinned: Bool
        var createdAt: Int
        var amount: Double
        var description: String
        var status: StrictWorklistAllocationStatus

        init(code: String, name: String, pinned: Bool, createdAt: Int, amount: Double, description: String, status: StrictWorklistAllocationStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.createdAt = createdAt
            self.amount = amount
            self.description = description
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

        func canMoveTo(_ next: StrictWorklistAllocationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == StrictWorklistAllocationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictWorklistAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict worklist allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("strict worklist allocation") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((amount - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictWorklistAllocation {
            return StrictWorklistAllocation(
                code: code,
                name: name,
                pinned: pinned,
                createdAt: createdAt,
                amount: amount,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict worklist allocation in status requested.
    static func newStrictWorklistAllocation(_ code: String, name: String) -> StrictWorklistAllocation {
        return StrictWorklistAllocation(
            code: code,
            name: name,
            pinned: false,
            createdAt: 0,
            amount: 0.0,
            description: "",
            status: StrictWorklistAllocationStatus.requested
        )
    }
}
