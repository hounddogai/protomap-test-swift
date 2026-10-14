import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift allocation is in its life cycle.
    enum ShiftAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A shift allocation. Its code is unique within a tenant.
    final class ShiftAllocation {
        var code: String
        var title: String
        var source: String
        var weight: Double
        var createdAt: Int
        var startsAt: Int
        var notes: String
        var sequence: Int
        var procedureCode: String
        var status: ShiftAllocationStatus

        init(code: String, title: String, source: String, weight: Double, createdAt: Int, startsAt: Int, notes: String, sequence: Int, procedureCode: String, status: ShiftAllocationStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.weight = weight
            self.createdAt = createdAt
            self.startsAt = startsAt
            self.notes = notes
            self.sequence = sequence
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: ShiftAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ShiftAllocationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("shift allocation") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(startsAt) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftAllocation {
            return ShiftAllocation(
                code: code,
                title: title,
                source: source,
                weight: weight,
                createdAt: createdAt,
                startsAt: startsAt,
                notes: notes,
                sequence: sequence,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a shift allocation in status proposed.
    static func newShiftAllocation(_ code: String, title: String) -> ShiftAllocation {
        return ShiftAllocation(
            code: code,
            title: title,
            source: "",
            weight: 0.0,
            createdAt: 0,
            startsAt: 0,
            notes: "",
            sequence: 0,
            procedureCode: "",
            status: ShiftAllocationStatus.proposed
        )
    }
}
