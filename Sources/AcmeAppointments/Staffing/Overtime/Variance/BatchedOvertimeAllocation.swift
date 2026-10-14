import AcmePlatform
import Foundation

extension Staffing {
    /// Where a batched overtime allocation is in its life cycle.
    enum BatchedOvertimeAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A batched overtime allocation. Its code is unique within a tenant.
    final class BatchedOvertimeAllocation {
        var code: String
        var title: String
        var createdAt: Int
        var weight: Double
        var floorValue: Double
        var endsAt: Int
        var active: Bool
        var version: Int
        var capacity: Int
        var payer: String
        var status: BatchedOvertimeAllocationStatus

        init(code: String, title: String, createdAt: Int, weight: Double, floorValue: Double, endsAt: Int, active: Bool, version: Int, capacity: Int, payer: String, status: BatchedOvertimeAllocationStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.weight = weight
            self.floorValue = floorValue
            self.endsAt = endsAt
            self.active = active
            self.version = version
            self.capacity = capacity
            self.payer = payer
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

        func canMoveTo(_ next: BatchedOvertimeAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BatchedOvertimeAllocationStatus.approved || next == BatchedOvertimeAllocationStatus.withdrawn
            case .approved:
                return next == BatchedOvertimeAllocationStatus.rejected || next == BatchedOvertimeAllocationStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: BatchedOvertimeAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched overtime allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("batched overtime allocation") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(capacity) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedOvertimeAllocation {
            return BatchedOvertimeAllocation(
                code: code,
                title: title,
                createdAt: createdAt,
                weight: weight,
                floorValue: floorValue,
                endsAt: endsAt,
                active: active,
                version: version,
                capacity: capacity,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched overtime allocation in status proposed.
    static func newBatchedOvertimeAllocation(_ code: String, title: String) -> BatchedOvertimeAllocation {
        return BatchedOvertimeAllocation(
            code: code,
            title: title,
            createdAt: 0,
            weight: 0.0,
            floorValue: 0.0,
            endsAt: 0,
            active: false,
            version: 0,
            capacity: 0,
            payer: "",
            status: BatchedOvertimeAllocationStatus.proposed
        )
    }
}
