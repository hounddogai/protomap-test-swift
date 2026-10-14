import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped recall assignment is in its life cycle.
    enum CappedRecallAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a capped recall assignment and its current status.
    final class CappedRecallAssignment {
        var code: String
        var title: String
        var copay: Double
        var specialty: String
        var rate: Double
        var score: Double
        var minimum: Double
        var revision: Int
        var ownerID: String
        var status: CappedRecallAssignmentStatus

        init(code: String, title: String, copay: Double, specialty: String, rate: Double, score: Double, minimum: Double, revision: Int, ownerID: String, status: CappedRecallAssignmentStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.specialty = specialty
            self.rate = rate
            self.score = score
            self.minimum = minimum
            self.revision = revision
            self.ownerID = ownerID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedRecallAssignmentStatus) -> Bool {
            switch status {
            case .new:
                return next == CappedRecallAssignmentStatus.running || next == CappedRecallAssignmentStatus.done
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CappedRecallAssignmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedRecallAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped recall assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("capped recall assignment") \(code)"
        }

        func adjustedValue() -> Double {
            return (rate * score * 100).rounded() / 100
        }

        func copyValue() -> CappedRecallAssignment {
            return CappedRecallAssignment(
                code: code,
                title: title,
                copay: copay,
                specialty: specialty,
                rate: rate,
                score: score,
                minimum: minimum,
                revision: revision,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped recall assignment in status new.
    static func newCappedRecallAssignment(_ code: String, title: String) -> CappedRecallAssignment {
        return CappedRecallAssignment(
            code: code,
            title: title,
            copay: 0.0,
            specialty: "",
            rate: 0.0,
            score: 0.0,
            minimum: 0.0,
            revision: 0,
            ownerID: "",
            status: CappedRecallAssignmentStatus.new
        )
    }
}
