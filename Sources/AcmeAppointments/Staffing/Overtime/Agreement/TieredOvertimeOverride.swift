import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered overtime override is in its life cycle.
    enum TieredOvertimeOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One tiered overtime override, with what the planners need to act on it.
    final class TieredOvertimeOverride {
        var code: String
        var name: String
        var priority: Int
        var approved: Bool
        var procedureCode: String
        var floorValue: Double
        var status: TieredOvertimeOverrideStatus

        init(code: String, name: String, priority: Int, approved: Bool, procedureCode: String, floorValue: Double, status: TieredOvertimeOverrideStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.approved = approved
            self.procedureCode = procedureCode
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredOvertimeOverrideStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == TieredOvertimeOverrideStatus.draining || next == TieredOvertimeOverrideStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: TieredOvertimeOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered overtime override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered overtime override") \(code)"
        }

        func projectedValue() -> Double {
            return (Double(priority) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> TieredOvertimeOverride {
            return TieredOvertimeOverride(
                code: code,
                name: name,
                priority: priority,
                approved: approved,
                procedureCode: procedureCode,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered overtime override in status idle.
    static func newTieredOvertimeOverride(_ code: String, name: String) -> TieredOvertimeOverride {
        return TieredOvertimeOverride(
            code: code,
            name: name,
            priority: 0,
            approved: false,
            procedureCode: "",
            floorValue: 0.0,
            status: TieredOvertimeOverrideStatus.idle
        )
    }
}
