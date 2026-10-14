import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution score is in its life cycle.
    enum SubstitutionScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A substitution score. Its code is unique within a tenant.
    final class SubstitutionScore {
        var code: String
        var name: String
        var bed: String
        var expiresAt: Int
        var patientRef: String
        var revision: Int
        var title: String
        var endsAt: Int
        var amount: Double
        var discount: Double
        var approved: Bool
        var status: SubstitutionScoreStatus

        init(code: String, name: String, bed: String, expiresAt: Int, patientRef: String, revision: Int, title: String, endsAt: Int, amount: Double, discount: Double, approved: Bool, status: SubstitutionScoreStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.expiresAt = expiresAt
            self.patientRef = patientRef
            self.revision = revision
            self.title = title
            self.endsAt = endsAt
            self.amount = amount
            self.discount = discount
            self.approved = approved
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

        func canMoveTo(_ next: SubstitutionScoreStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == SubstitutionScoreStatus.suspended || next == SubstitutionScoreStatus.closed
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

        func moveTo(_ next: SubstitutionScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveExposure() -> Double {
            return ((Double(revision) + discount) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionScore {
            return SubstitutionScore(
                code: code,
                name: name,
                bed: bed,
                expiresAt: expiresAt,
                patientRef: patientRef,
                revision: revision,
                title: title,
                endsAt: endsAt,
                amount: amount,
                discount: discount,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a substitution score in status draft.
    static func newSubstitutionScore(_ code: String, name: String) -> SubstitutionScore {
        return SubstitutionScore(
            code: code,
            name: name,
            bed: "",
            expiresAt: 0,
            patientRef: "",
            revision: 0,
            title: "",
            endsAt: 0,
            amount: 0.0,
            discount: 0.0,
            approved: false,
            status: SubstitutionScoreStatus.draft
        )
    }
}
