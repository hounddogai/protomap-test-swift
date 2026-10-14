import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority rollup is in its life cycle.
    enum PriorityRollupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A priority rollup as the priority team keeps it.
    final class PriorityRollup {
        var code: String
        var name: String
        var approved: Bool
        var acuity: Int
        var timezone: String
        var status: PriorityRollupStatus

        init(code: String, name: String, approved: Bool, acuity: Int, timezone: String, status: PriorityRollupStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.acuity = acuity
            self.timezone = timezone
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

        func canMoveTo(_ next: PriorityRollupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PriorityRollupStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PriorityRollupStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> PriorityRollup {
            return PriorityRollup(
                code: code,
                name: name,
                approved: approved,
                acuity: acuity,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a priority rollup in status proposed.
    static func newPriorityRollup(_ code: String, name: String) -> PriorityRollup {
        return PriorityRollup(
            code: code,
            name: name,
            approved: false,
            acuity: 0,
            timezone: "",
            status: PriorityRollupStatus.proposed
        )
    }
}
