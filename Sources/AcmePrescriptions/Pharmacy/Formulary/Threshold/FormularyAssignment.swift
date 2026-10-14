import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary assignment is in its life cycle.
    enum FormularyAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A formulary assignment. Its code is unique within a tenant.
    final class FormularyAssignment {
        var code: String
        var name: String
        var budget: Double
        var revision: Int
        var contactEmail: String
        var attributes: [String: String]
        var amount: Double
        var status: FormularyAssignmentStatus

        init(code: String, name: String, budget: Double, revision: Int, contactEmail: String, attributes: [String: String], amount: Double, status: FormularyAssignmentStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.revision = revision
            self.contactEmail = contactEmail
            self.attributes = attributes
            self.amount = amount
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

        func canMoveTo(_ next: FormularyAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FormularyAssignmentStatus.approved || next == FormularyAssignmentStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: FormularyAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
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

        func projectedLoad() -> Double {
            return ((budget + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> FormularyAssignment {
            return FormularyAssignment(
                code: code,
                name: name,
                budget: budget,
                revision: revision,
                contactEmail: contactEmail,
                attributes: attributes,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a formulary assignment in status proposed.
    static func newFormularyAssignment(_ code: String, name: String) -> FormularyAssignment {
        return FormularyAssignment(
            code: code,
            name: name,
            budget: 0.0,
            revision: 0,
            contactEmail: "",
            attributes: [:],
            amount: 0.0,
            status: FormularyAssignmentStatus.proposed
        )
    }
}
