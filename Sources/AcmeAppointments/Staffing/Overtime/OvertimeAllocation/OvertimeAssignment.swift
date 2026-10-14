import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime assignment is in its life cycle.
    enum OvertimeAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a overtime assignment and its current status.
    final class OvertimeAssignment {
        var code: String
        var name: String
        var active: Bool
        var amount: Double
        var rate: Double
        var status: OvertimeAssignmentStatus

        init(code: String, name: String, active: Bool, amount: Double, rate: Double, status: OvertimeAssignmentStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.amount = amount
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OvertimeAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == OvertimeAssignmentStatus.inReview || next == OvertimeAssignmentStatus.reopened
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: OvertimeAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedExposure() -> Double {
            return (amount * rate * 100).rounded() / 100
        }

        func copyValue() -> OvertimeAssignment {
            return OvertimeAssignment(
                code: code,
                name: name,
                active: active,
                amount: amount,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a overtime assignment in status open.
    static func newOvertimeAssignment(_ code: String, name: String) -> OvertimeAssignment {
        return OvertimeAssignment(
            code: code,
            name: name,
            active: false,
            amount: 0.0,
            rate: 0.0,
            status: OvertimeAssignmentStatus.`open`
        )
    }
}
