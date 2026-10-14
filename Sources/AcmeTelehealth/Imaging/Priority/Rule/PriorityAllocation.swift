import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority allocation is in its life cycle.
    enum PriorityAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a priority allocation and its current status.
    final class PriorityAllocation {
        var code: String
        var title: String
        var maximum: Double
        var score: Double
        var copay: Double
        var description: String
        var archived: Bool
        var approved: Bool
        var status: PriorityAllocationStatus

        init(code: String, title: String, maximum: Double, score: Double, copay: Double, description: String, archived: Bool, approved: Bool, status: PriorityAllocationStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.score = score
            self.copay = copay
            self.description = description
            self.archived = archived
            self.approved = approved
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

        func canMoveTo(_ next: PriorityAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PriorityAllocationStatus.rejected || next == PriorityAllocationStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PriorityAllocationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("priority allocation") \(code)"
        }

        func adjustedTotal() -> Double {
            return (score * maximum * 100).rounded() / 100
        }

        func copyValue() -> PriorityAllocation {
            return PriorityAllocation(
                code: code,
                title: title,
                maximum: maximum,
                score: score,
                copay: copay,
                description: description,
                archived: archived,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a priority allocation in status proposed.
    static func newPriorityAllocation(_ code: String, title: String) -> PriorityAllocation {
        return PriorityAllocation(
            code: code,
            title: title,
            maximum: 0.0,
            score: 0.0,
            copay: 0.0,
            description: "",
            archived: false,
            approved: false,
            status: PriorityAllocationStatus.proposed
        )
    }
}
