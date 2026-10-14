import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense allocation is in its life cycle.
    enum DispenseAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A dispense allocation as the dispense team keeps it.
    final class DispenseAllocation {
        var code: String
        var label: String
        var clinicianID: String
        var checksum: String
        var approved: Bool
        var capacity: Int
        var durationMinutes: Int
        var updatedAt: Int
        var status: DispenseAllocationStatus

        init(code: String, label: String, clinicianID: String, checksum: String, approved: Bool, capacity: Int, durationMinutes: Int, updatedAt: Int, status: DispenseAllocationStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.checksum = checksum
            self.approved = approved
            self.capacity = capacity
            self.durationMinutes = durationMinutes
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: DispenseAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DispenseAllocationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("dispense allocation") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(durationMinutes) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseAllocation {
            return DispenseAllocation(
                code: code,
                label: label,
                clinicianID: clinicianID,
                checksum: checksum,
                approved: approved,
                capacity: capacity,
                durationMinutes: durationMinutes,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a dispense allocation in status proposed.
    static func newDispenseAllocation(_ code: String, label: String) -> DispenseAllocation {
        return DispenseAllocation(
            code: code,
            label: label,
            clinicianID: "",
            checksum: "",
            approved: false,
            capacity: 0,
            durationMinutes: 0,
            updatedAt: 0,
            status: DispenseAllocationStatus.proposed
        )
    }
}
