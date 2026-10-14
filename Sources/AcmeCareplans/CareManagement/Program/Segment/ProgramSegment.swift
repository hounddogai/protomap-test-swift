import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program segment is in its life cycle.
    enum ProgramSegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a program segment and its current status.
    final class ProgramSegment {
        var code: String
        var name: String
        var maximum: Double
        var budget: Double
        var timezone: String
        var bed: String
        var visitMinutes: Int
        var revision: Int
        var status: ProgramSegmentStatus

        init(code: String, name: String, maximum: Double, budget: Double, timezone: String, bed: String, visitMinutes: Int, revision: Int, status: ProgramSegmentStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.budget = budget
            self.timezone = timezone
            self.bed = bed
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: ProgramSegmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == ProgramSegmentStatus.warming || next == ProgramSegmentStatus.ready
            case .warming:
                return next == ProgramSegmentStatus.draining || next == ProgramSegmentStatus.stopped
            case .ready:
                return next == ProgramSegmentStatus.draining || next == ProgramSegmentStatus.stopped
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

        func moveTo(_ next: ProgramSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedExposure() -> Double {
            return (maximum * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ProgramSegment {
            return ProgramSegment(
                code: code,
                name: name,
                maximum: maximum,
                budget: budget,
                timezone: timezone,
                bed: bed,
                visitMinutes: visitMinutes,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a program segment in status idle.
    static func newProgramSegment(_ code: String, name: String) -> ProgramSegment {
        return ProgramSegment(
            code: code,
            name: name,
            maximum: 0.0,
            budget: 0.0,
            timezone: "",
            bed: "",
            visitMinutes: 0,
            revision: 0,
            status: ProgramSegmentStatus.idle
        )
    }
}
