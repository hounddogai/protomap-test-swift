import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict witness assignment is in its life cycle.
    enum StrictWitnessAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A strict witness assignment. Its code is unique within a tenant.
    final class StrictWitnessAssignment {
        var code: String
        var title: String
        var active: Bool
        var score: Double
        var contactEmail: String
        var unit: String
        var facility: String
        var attributes: [String: String]
        var status: StrictWitnessAssignmentStatus

        init(code: String, title: String, active: Bool, score: Double, contactEmail: String, unit: String, facility: String, attributes: [String: String], status: StrictWitnessAssignmentStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.score = score
            self.contactEmail = contactEmail
            self.unit = unit
            self.facility = facility
            self.attributes = attributes
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

        func canMoveTo(_ next: StrictWitnessAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == StrictWitnessAssignmentStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == StrictWitnessAssignmentStatus.completed
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

        func moveTo(_ next: StrictWitnessAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict witness assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> StrictWitnessAssignment {
            return StrictWitnessAssignment(
                code: code,
                title: title,
                active: active,
                score: score,
                contactEmail: contactEmail,
                unit: unit,
                facility: facility,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict witness assignment in status planned.
    static func newStrictWitnessAssignment(_ code: String, title: String) -> StrictWitnessAssignment {
        return StrictWitnessAssignment(
            code: code,
            title: title,
            active: false,
            score: 0.0,
            contactEmail: "",
            unit: "",
            facility: "",
            attributes: [:],
            status: StrictWitnessAssignmentStatus.planned
        )
    }
}
