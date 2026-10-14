import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped reference range allocation is in its life cycle.
    enum CappedReferenceRangeAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a capped reference range allocation and its current status.
    final class CappedReferenceRangeAllocation {
        var code: String
        var name: String
        var discount: Double
        var sequence: Int
        var budget: Double
        var startsAt: Int
        var status: CappedReferenceRangeAllocationStatus

        init(code: String, name: String, discount: Double, sequence: Int, budget: Double, startsAt: Int, status: CappedReferenceRangeAllocationStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.sequence = sequence
            self.budget = budget
            self.startsAt = startsAt
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

        func canMoveTo(_ next: CappedReferenceRangeAllocationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CappedReferenceRangeAllocationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedReferenceRangeAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped reference range allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedVolume() -> Double {
            return (Double(startsAt) * budget * 100).rounded() / 100
        }

        func copyValue() -> CappedReferenceRangeAllocation {
            return CappedReferenceRangeAllocation(
                code: code,
                name: name,
                discount: discount,
                sequence: sequence,
                budget: budget,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped reference range allocation in status requested.
    static func newCappedReferenceRangeAllocation(_ code: String, name: String) -> CappedReferenceRangeAllocation {
        return CappedReferenceRangeAllocation(
            code: code,
            name: name,
            discount: 0.0,
            sequence: 0,
            budget: 0.0,
            startsAt: 0,
            status: CappedReferenceRangeAllocationStatus.requested
        )
    }
}
