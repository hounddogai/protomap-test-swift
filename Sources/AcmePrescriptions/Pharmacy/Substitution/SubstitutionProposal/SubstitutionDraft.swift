import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution draft is in its life cycle.
    enum SubstitutionDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A substitution draft as the substitution team keeps it.
    final class SubstitutionDraft {
        var code: String
        var name: String
        var notes: String
        var summary: String
        var endsAt: Int
        var updatedAt: Int
        var encounterID: String
        var ratio: Double
        var limit: Int
        var score: Double
        var label: String
        var status: SubstitutionDraftStatus

        init(code: String, name: String, notes: String, summary: String, endsAt: Int, updatedAt: Int, encounterID: String, ratio: Double, limit: Int, score: Double, label: String, status: SubstitutionDraftStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.summary = summary
            self.endsAt = endsAt
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.ratio = ratio
            self.limit = limit
            self.score = score
            self.label = label
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

        func canMoveTo(_ next: SubstitutionDraftStatus) -> Bool {
            switch status {
            case .draft:
                return next == SubstitutionDraftStatus.pending || next == SubstitutionDraftStatus.active
            case .pending:
                return next == SubstitutionDraftStatus.active
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == SubstitutionDraftStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("substitution draft") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(endsAt) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionDraft {
            return SubstitutionDraft(
                code: code,
                name: name,
                notes: notes,
                summary: summary,
                endsAt: endsAt,
                updatedAt: updatedAt,
                encounterID: encounterID,
                ratio: ratio,
                limit: limit,
                score: score,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a substitution draft in status draft.
    static func newSubstitutionDraft(_ code: String, name: String) -> SubstitutionDraft {
        return SubstitutionDraft(
            code: code,
            name: name,
            notes: "",
            summary: "",
            endsAt: 0,
            updatedAt: 0,
            encounterID: "",
            ratio: 0.0,
            limit: 0,
            score: 0.0,
            label: "",
            status: SubstitutionDraftStatus.draft
        )
    }
}
