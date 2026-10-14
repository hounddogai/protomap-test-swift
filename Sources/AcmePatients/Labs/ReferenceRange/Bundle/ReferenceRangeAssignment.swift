import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range assignment is in its life cycle.
    enum ReferenceRangeAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One reference range assignment, with what the planners need to act on it.
    final class ReferenceRangeAssignment {
        var code: String
        var name: String
        var bed: String
        var dosageMg: Double
        var capacity: Int
        var procedureCode: String
        var pinned: Bool
        var startsAt: Int
        var channel: String
        var createdAt: Int
        var status: ReferenceRangeAssignmentStatus

        init(code: String, name: String, bed: String, dosageMg: Double, capacity: Int, procedureCode: String, pinned: Bool, startsAt: Int, channel: String, createdAt: Int, status: ReferenceRangeAssignmentStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.procedureCode = procedureCode
            self.pinned = pinned
            self.startsAt = startsAt
            self.channel = channel
            self.createdAt = createdAt
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

        func canMoveTo(_ next: ReferenceRangeAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ReferenceRangeAssignmentStatus.ready || next == ReferenceRangeAssignmentStatus.stopped
            case .ready:
                return next == ReferenceRangeAssignmentStatus.draining
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

        func moveTo(_ next: ReferenceRangeAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedValue() -> Double {
            return ((dosageMg - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeAssignment {
            return ReferenceRangeAssignment(
                code: code,
                name: name,
                bed: bed,
                dosageMg: dosageMg,
                capacity: capacity,
                procedureCode: procedureCode,
                pinned: pinned,
                startsAt: startsAt,
                channel: channel,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a reference range assignment in status idle.
    static func newReferenceRangeAssignment(_ code: String, name: String) -> ReferenceRangeAssignment {
        return ReferenceRangeAssignment(
            code: code,
            name: name,
            bed: "",
            dosageMg: 0.0,
            capacity: 0,
            procedureCode: "",
            pinned: false,
            startsAt: 0,
            channel: "",
            createdAt: 0,
            status: ReferenceRangeAssignmentStatus.idle
        )
    }
}
