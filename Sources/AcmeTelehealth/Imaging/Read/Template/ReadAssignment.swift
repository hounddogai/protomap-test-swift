import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read assignment is in its life cycle.
    enum ReadAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One read assignment, with what the planners need to act on it.
    final class ReadAssignment {
        var code: String
        var name: String
        var patientRef: String
        var timezone: String
        var priority: Int
        var approved: Bool
        var payer: String
        var budget: Double
        var status: ReadAssignmentStatus

        init(code: String, name: String, patientRef: String, timezone: String, priority: Int, approved: Bool, payer: String, budget: Double, status: ReadAssignmentStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.timezone = timezone
            self.priority = priority
            self.approved = approved
            self.payer = payer
            self.budget = budget
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

        func canMoveTo(_ next: ReadAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ReadAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedExposure() -> Double {
            return ((budget - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ReadAssignment {
            return ReadAssignment(
                code: code,
                name: name,
                patientRef: patientRef,
                timezone: timezone,
                priority: priority,
                approved: approved,
                payer: payer,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a read assignment in status idle.
    static func newReadAssignment(_ code: String, name: String) -> ReadAssignment {
        return ReadAssignment(
            code: code,
            name: name,
            patientRef: "",
            timezone: "",
            priority: 0,
            approved: false,
            payer: "",
            budget: 0.0,
            status: ReadAssignmentStatus.idle
        )
    }
}
