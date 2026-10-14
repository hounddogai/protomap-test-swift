import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction assignment is in its life cycle.
    enum InteractionAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A interaction assignment as the interaction team keeps it.
    final class InteractionAssignment {
        var code: String
        var title: String
        var attributes: [String: String]
        var procedureCode: String
        var budget: Double
        var durationMinutes: Int
        var status: InteractionAssignmentStatus

        init(code: String, title: String, attributes: [String: String], procedureCode: String, budget: Double, durationMinutes: Int, status: InteractionAssignmentStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.procedureCode = procedureCode
            self.budget = budget
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InteractionAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == InteractionAssignmentStatus.withdrawn
            case .approved:
                return next == InteractionAssignmentStatus.rejected || next == InteractionAssignmentStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: InteractionAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func weightedLoad() -> Double {
            return (budget * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> InteractionAssignment {
            return InteractionAssignment(
                code: code,
                title: title,
                attributes: attributes,
                procedureCode: procedureCode,
                budget: budget,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a interaction assignment in status proposed.
    static func newInteractionAssignment(_ code: String, title: String) -> InteractionAssignment {
        return InteractionAssignment(
            code: code,
            title: title,
            attributes: [:],
            procedureCode: "",
            budget: 0.0,
            durationMinutes: 0,
            status: InteractionAssignmentStatus.proposed
        )
    }
}
