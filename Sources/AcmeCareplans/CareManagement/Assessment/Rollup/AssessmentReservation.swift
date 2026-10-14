import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment reservation is in its life cycle.
    enum AssessmentReservationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A assessment reservation. Its code is unique within a tenant.
    final class AssessmentReservation {
        var code: String
        var name: String
        var ceiling: Double
        var label: String
        var reviewer: String
        var minimum: Double
        var maximum: Double
        var status: AssessmentReservationStatus

        init(code: String, name: String, ceiling: Double, label: String, reviewer: String, minimum: Double, maximum: Double, status: AssessmentReservationStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.label = label
            self.reviewer = reviewer
            self.minimum = minimum
            self.maximum = maximum
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

        func canMoveTo(_ next: AssessmentReservationStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AssessmentReservationStatus.reopened || next == AssessmentReservationStatus.archived
            case .reopened:
                return next == AssessmentReservationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func projectedValue() -> Double {
            return ((minimum - maximum) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentReservation {
            return AssessmentReservation(
                code: code,
                name: name,
                ceiling: ceiling,
                label: label,
                reviewer: reviewer,
                minimum: minimum,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a assessment reservation in status open.
    static func newAssessmentReservation(_ code: String, name: String) -> AssessmentReservation {
        return AssessmentReservation(
            code: code,
            name: name,
            ceiling: 0.0,
            label: "",
            reviewer: "",
            minimum: 0.0,
            maximum: 0.0,
            status: AssessmentReservationStatus.`open`
        )
    }
}
