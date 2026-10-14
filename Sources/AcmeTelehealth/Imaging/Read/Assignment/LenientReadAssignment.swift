import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient read assignment is in its life cycle.
    enum LenientReadAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient read assignment as the read team keeps it.
    final class LenientReadAssignment {
        var code: String
        var name: String
        var allergy: String
        var graceDays: Int
        var notes: String
        var attempts: Int
        var expiresAt: Int
        var procedureCode: String
        var source: String
        var tags: [String]
        var status: LenientReadAssignmentStatus

        init(code: String, name: String, allergy: String, graceDays: Int, notes: String, attempts: Int, expiresAt: Int, procedureCode: String, source: String, tags: [String], status: LenientReadAssignmentStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.graceDays = graceDays
            self.notes = notes
            self.attempts = attempts
            self.expiresAt = expiresAt
            self.procedureCode = procedureCode
            self.source = source
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientReadAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientReadAssignmentStatus.suspended || next == LenientReadAssignmentStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LenientReadAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient read assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return (Double(graceDays) * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> LenientReadAssignment {
            return LenientReadAssignment(
                code: code,
                name: name,
                allergy: allergy,
                graceDays: graceDays,
                notes: notes,
                attempts: attempts,
                expiresAt: expiresAt,
                procedureCode: procedureCode,
                source: source,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a lenient read assignment in status draft.
    static func newLenientReadAssignment(_ code: String, name: String) -> LenientReadAssignment {
        return LenientReadAssignment(
            code: code,
            name: name,
            allergy: "",
            graceDays: 0,
            notes: "",
            attempts: 0,
            expiresAt: 0,
            procedureCode: "",
            source: "",
            tags: [],
            status: LenientReadAssignmentStatus.draft
        )
    }
}
