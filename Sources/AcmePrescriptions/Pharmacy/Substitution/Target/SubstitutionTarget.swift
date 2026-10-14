import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution target is in its life cycle.
    enum SubstitutionTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a substitution target and its current status.
    final class SubstitutionTarget {
        var code: String
        var name: String
        var amount: Double
        var sequence: Int
        var approved: Bool
        var label: String
        var ceiling: Double
        var notes: String
        var attributes: [String: String]
        var status: SubstitutionTargetStatus

        init(code: String, name: String, amount: Double, sequence: Int, approved: Bool, label: String, ceiling: Double, notes: String, attributes: [String: String], status: SubstitutionTargetStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.sequence = sequence
            self.approved = approved
            self.label = label
            self.ceiling = ceiling
            self.notes = notes
            self.attributes = attributes
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

        func canMoveTo(_ next: SubstitutionTargetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == SubstitutionTargetStatus.withdrawn
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

        func moveTo(_ next: SubstitutionTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("substitution target") \(code)"
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

        func netVolume() -> Double {
            return ((amount - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionTarget {
            return SubstitutionTarget(
                code: code,
                name: name,
                amount: amount,
                sequence: sequence,
                approved: approved,
                label: label,
                ceiling: ceiling,
                notes: notes,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a substitution target in status proposed.
    static func newSubstitutionTarget(_ code: String, name: String) -> SubstitutionTarget {
        return SubstitutionTarget(
            code: code,
            name: name,
            amount: 0.0,
            sequence: 0,
            approved: false,
            label: "",
            ceiling: 0.0,
            notes: "",
            attributes: [:],
            status: SubstitutionTargetStatus.proposed
        )
    }
}
