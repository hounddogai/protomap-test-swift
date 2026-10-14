import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial allocation is in its life cycle.
    enum DenialAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A denial allocation. Its code is unique within a tenant.
    final class DenialAllocation {
        var code: String
        var title: String
        var durationMinutes: Int
        var archived: Bool
        var reviewer: String
        var externalRef: String
        var ownerID: String
        var status: DenialAllocationStatus

        init(code: String, title: String, durationMinutes: Int, archived: Bool, reviewer: String, externalRef: String, ownerID: String, status: DenialAllocationStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.archived = archived
            self.reviewer = reviewer
            self.externalRef = externalRef
            self.ownerID = ownerID
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

        func canMoveTo(_ next: DenialAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DenialAllocationStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DenialAllocationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> DenialAllocation {
            return DenialAllocation(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                archived: archived,
                reviewer: reviewer,
                externalRef: externalRef,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a denial allocation in status proposed.
    static func newDenialAllocation(_ code: String, title: String) -> DenialAllocation {
        return DenialAllocation(
            code: code,
            title: title,
            durationMinutes: 0,
            archived: false,
            reviewer: "",
            externalRef: "",
            ownerID: "",
            status: DenialAllocationStatus.proposed
        )
    }
}
