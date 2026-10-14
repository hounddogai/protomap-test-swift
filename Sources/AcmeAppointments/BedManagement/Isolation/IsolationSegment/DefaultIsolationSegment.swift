import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default isolation segment is in its life cycle.
    enum DefaultIsolationSegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default isolation segment as the isolation team keeps it.
    final class DefaultIsolationSegment {
        var code: String
        var name: String
        var patientRef: String
        var dosageMg: Double
        var sequence: Int
        var endsAt: Int
        var ownerID: String
        var priority: Int
        var maximum: Double
        var revision: Int
        var status: DefaultIsolationSegmentStatus

        init(code: String, name: String, patientRef: String, dosageMg: Double, sequence: Int, endsAt: Int, ownerID: String, priority: Int, maximum: Double, revision: Int, status: DefaultIsolationSegmentStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.dosageMg = dosageMg
            self.sequence = sequence
            self.endsAt = endsAt
            self.ownerID = ownerID
            self.priority = priority
            self.maximum = maximum
            self.revision = revision
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

        func canMoveTo(_ next: DefaultIsolationSegmentStatus) -> Bool {
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
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == DefaultIsolationSegmentStatus.draining || next == DefaultIsolationSegmentStatus.stopped
            case .draining:
                return next == DefaultIsolationSegmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultIsolationSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default isolation segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedValue() -> Double {
            return (Double(endsAt) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> DefaultIsolationSegment {
            return DefaultIsolationSegment(
                code: code,
                name: name,
                patientRef: patientRef,
                dosageMg: dosageMg,
                sequence: sequence,
                endsAt: endsAt,
                ownerID: ownerID,
                priority: priority,
                maximum: maximum,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default isolation segment in status idle.
    static func newDefaultIsolationSegment(_ code: String, name: String) -> DefaultIsolationSegment {
        return DefaultIsolationSegment(
            code: code,
            name: name,
            patientRef: "",
            dosageMg: 0.0,
            sequence: 0,
            endsAt: 0,
            ownerID: "",
            priority: 0,
            maximum: 0.0,
            revision: 0,
            status: DefaultIsolationSegmentStatus.idle
        )
    }
}
