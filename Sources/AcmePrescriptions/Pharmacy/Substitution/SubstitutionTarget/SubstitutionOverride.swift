import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution override is in its life cycle.
    enum SubstitutionOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a substitution override and its current status.
    final class SubstitutionOverride {
        var code: String
        var name: String
        var specialty: String
        var description: String
        var visible: Bool
        var bed: String
        var expiresAt: Int
        var status: SubstitutionOverrideStatus

        init(code: String, name: String, specialty: String, description: String, visible: Bool, bed: String, expiresAt: Int, status: SubstitutionOverrideStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.description = description
            self.visible = visible
            self.bed = bed
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: SubstitutionOverrideStatus) -> Bool {
            switch status {
            case .draft:
                return next == SubstitutionOverrideStatus.active
            case .pending:
                return next == SubstitutionOverrideStatus.active
            case .active:
                return next == SubstitutionOverrideStatus.suspended
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

        func moveTo(_ next: SubstitutionOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("substitution override") \(code)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> SubstitutionOverride {
            return SubstitutionOverride(
                code: code,
                name: name,
                specialty: specialty,
                description: description,
                visible: visible,
                bed: bed,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a substitution override in status draft.
    static func newSubstitutionOverride(_ code: String, name: String) -> SubstitutionOverride {
        return SubstitutionOverride(
            code: code,
            name: name,
            specialty: "",
            description: "",
            visible: false,
            bed: "",
            expiresAt: 0,
            status: SubstitutionOverrideStatus.draft
        )
    }
}
