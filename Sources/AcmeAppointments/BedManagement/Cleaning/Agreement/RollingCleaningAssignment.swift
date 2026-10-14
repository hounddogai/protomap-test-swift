import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling cleaning assignment is in its life cycle.
    enum RollingCleaningAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One rolling cleaning assignment, with what the planners need to act on it.
    final class RollingCleaningAssignment {
        var code: String
        var label: String
        var externalRef: String
        var limit: Int
        var patientRef: String
        var budget: Double
        var channel: String
        var ownerID: String
        var rate: Double
        var ward: String
        var status: RollingCleaningAssignmentStatus

        init(code: String, label: String, externalRef: String, limit: Int, patientRef: String, budget: Double, channel: String, ownerID: String, rate: Double, ward: String, status: RollingCleaningAssignmentStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.limit = limit
            self.patientRef = patientRef
            self.budget = budget
            self.channel = channel
            self.ownerID = ownerID
            self.rate = rate
            self.ward = ward
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

        func canMoveTo(_ next: RollingCleaningAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == RollingCleaningAssignmentStatus.stopped
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
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

        func moveTo(_ next: RollingCleaningAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling cleaning assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedLoad() -> Double {
            return (budget * rate * 100).rounded() / 100
        }

        func copyValue() -> RollingCleaningAssignment {
            return RollingCleaningAssignment(
                code: code,
                label: label,
                externalRef: externalRef,
                limit: limit,
                patientRef: patientRef,
                budget: budget,
                channel: channel,
                ownerID: ownerID,
                rate: rate,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a rolling cleaning assignment in status idle.
    static func newRollingCleaningAssignment(_ code: String, label: String) -> RollingCleaningAssignment {
        return RollingCleaningAssignment(
            code: code,
            label: label,
            externalRef: "",
            limit: 0,
            patientRef: "",
            budget: 0.0,
            channel: "",
            ownerID: "",
            rate: 0.0,
            ward: "",
            status: RollingCleaningAssignmentStatus.idle
        )
    }
}
