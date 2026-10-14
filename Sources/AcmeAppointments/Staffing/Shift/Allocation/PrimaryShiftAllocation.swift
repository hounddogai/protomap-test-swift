import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary shift allocation is in its life cycle.
    enum PrimaryShiftAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A primary shift allocation. Its code is unique within a tenant.
    final class PrimaryShiftAllocation {
        var code: String
        var title: String
        var pinned: Bool
        var visible: Bool
        var phone: String
        var segment: String
        var budget: Double
        var archived: Bool
        var weight: Double
        var createdAt: Int
        var status: PrimaryShiftAllocationStatus

        init(code: String, title: String, pinned: Bool, visible: Bool, phone: String, segment: String, budget: Double, archived: Bool, weight: Double, createdAt: Int, status: PrimaryShiftAllocationStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.visible = visible
            self.phone = phone
            self.segment = segment
            self.budget = budget
            self.archived = archived
            self.weight = weight
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryShiftAllocationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == PrimaryShiftAllocationStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == PrimaryShiftAllocationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryShiftAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary shift allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary shift allocation") \(code)"
        }

        func weightedExposure() -> Double {
            return ((weight + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryShiftAllocation {
            return PrimaryShiftAllocation(
                code: code,
                title: title,
                pinned: pinned,
                visible: visible,
                phone: phone,
                segment: segment,
                budget: budget,
                archived: archived,
                weight: weight,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a primary shift allocation in status planned.
    static func newPrimaryShiftAllocation(_ code: String, title: String) -> PrimaryShiftAllocation {
        return PrimaryShiftAllocation(
            code: code,
            title: title,
            pinned: false,
            visible: false,
            phone: "",
            segment: "",
            budget: 0.0,
            archived: false,
            weight: 0.0,
            createdAt: 0,
            status: PrimaryShiftAllocationStatus.planned
        )
    }
}
