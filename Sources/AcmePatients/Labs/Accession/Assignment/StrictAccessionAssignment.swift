import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict accession assignment is in its life cycle.
    enum StrictAccessionAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A strict accession assignment as the accession team keeps it.
    final class StrictAccessionAssignment {
        var code: String
        var title: String
        var amount: Double
        var attributes: [String: String]
        var dosageMg: Double
        var specialty: String
        var endsAt: Int
        var notes: String
        var status: StrictAccessionAssignmentStatus

        init(code: String, title: String, amount: Double, attributes: [String: String], dosageMg: Double, specialty: String, endsAt: Int, notes: String, status: StrictAccessionAssignmentStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.attributes = attributes
            self.dosageMg = dosageMg
            self.specialty = specialty
            self.endsAt = endsAt
            self.notes = notes
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

        func canMoveTo(_ next: StrictAccessionAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StrictAccessionAssignmentStatus.inReview || next == StrictAccessionAssignmentStatus.resolved
            case .inReview:
                return next == StrictAccessionAssignmentStatus.archived
            case .resolved:
                return next == StrictAccessionAssignmentStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: StrictAccessionAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict accession assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func effectiveValue() -> Double {
            return (dosageMg * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> StrictAccessionAssignment {
            return StrictAccessionAssignment(
                code: code,
                title: title,
                amount: amount,
                attributes: attributes,
                dosageMg: dosageMg,
                specialty: specialty,
                endsAt: endsAt,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict accession assignment in status open.
    static func newStrictAccessionAssignment(_ code: String, title: String) -> StrictAccessionAssignment {
        return StrictAccessionAssignment(
            code: code,
            title: title,
            amount: 0.0,
            attributes: [:],
            dosageMg: 0.0,
            specialty: "",
            endsAt: 0,
            notes: "",
            status: StrictAccessionAssignmentStatus.`open`
        )
    }
}
