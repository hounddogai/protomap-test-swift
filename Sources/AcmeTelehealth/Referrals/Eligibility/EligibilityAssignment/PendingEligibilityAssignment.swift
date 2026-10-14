import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending eligibility assignment is in its life cycle.
    enum PendingEligibilityAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A pending eligibility assignment. Its code is unique within a tenant.
    final class PendingEligibilityAssignment {
        var code: String
        var title: String
        var patientRef: String
        var score: Double
        var name: String
        var unit: String
        var rate: Double
        var revision: Int
        var ceiling: Double
        var retries: Int
        var status: PendingEligibilityAssignmentStatus

        init(code: String, title: String, patientRef: String, score: Double, name: String, unit: String, rate: Double, revision: Int, ceiling: Double, retries: Int, status: PendingEligibilityAssignmentStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.score = score
            self.name = name
            self.unit = unit
            self.rate = rate
            self.revision = revision
            self.ceiling = ceiling
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingEligibilityAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == PendingEligibilityAssignmentStatus.scheduled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PendingEligibilityAssignmentStatus.completed || next == PendingEligibilityAssignmentStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PendingEligibilityAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending eligibility assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedVolume() -> Double {
            return (score * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> PendingEligibilityAssignment {
            return PendingEligibilityAssignment(
                code: code,
                title: title,
                patientRef: patientRef,
                score: score,
                name: name,
                unit: unit,
                rate: rate,
                revision: revision,
                ceiling: ceiling,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending eligibility assignment in status planned.
    static func newPendingEligibilityAssignment(_ code: String, title: String) -> PendingEligibilityAssignment {
        return PendingEligibilityAssignment(
            code: code,
            title: title,
            patientRef: "",
            score: 0.0,
            name: "",
            unit: "",
            rate: 0.0,
            revision: 0,
            ceiling: 0.0,
            retries: 0,
            status: PendingEligibilityAssignmentStatus.planned
        )
    }
}
