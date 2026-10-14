import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure assignment is in its life cycle.
    enum ClosureAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One closure assignment, with what the planners need to act on it.
    final class ClosureAssignment {
        var code: String
        var label: String
        var floorValue: Double
        var procedureCode: String
        var approved: Bool
        var score: Double
        var title: String
        var specialty: String
        var checksum: String
        var amount: Double
        var status: ClosureAssignmentStatus

        init(code: String, label: String, floorValue: Double, procedureCode: String, approved: Bool, score: Double, title: String, specialty: String, checksum: String, amount: Double, status: ClosureAssignmentStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.procedureCode = procedureCode
            self.approved = approved
            self.score = score
            self.title = title
            self.specialty = specialty
            self.checksum = checksum
            self.amount = amount
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

        func canMoveTo(_ next: ClosureAssignmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ClosureAssignmentStatus.failed
            case .done:
                return next == ClosureAssignmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("closure assignment") \(code)"
        }

        func projectedTotal() -> Double {
            return (floorValue * amount * 100).rounded() / 100
        }

        func copyValue() -> ClosureAssignment {
            return ClosureAssignment(
                code: code,
                label: label,
                floorValue: floorValue,
                procedureCode: procedureCode,
                approved: approved,
                score: score,
                title: title,
                specialty: specialty,
                checksum: checksum,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a closure assignment in status new.
    static func newClosureAssignment(_ code: String, label: String) -> ClosureAssignment {
        return ClosureAssignment(
            code: code,
            label: label,
            floorValue: 0.0,
            procedureCode: "",
            approved: false,
            score: 0.0,
            title: "",
            specialty: "",
            checksum: "",
            amount: 0.0,
            status: ClosureAssignmentStatus.new
        )
    }
}
