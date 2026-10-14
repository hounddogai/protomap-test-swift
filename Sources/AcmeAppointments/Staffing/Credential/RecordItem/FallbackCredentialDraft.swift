import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback credential draft is in its life cycle.
    enum FallbackCredentialDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A fallback credential draft as the credential team keeps it.
    final class FallbackCredentialDraft {
        var code: String
        var name: String
        var expiresAt: Int
        var active: Bool
        var diagnosisCode: String
        var archived: Bool
        var limit: Int
        var timezone: String
        var score: Double
        var procedureCode: String
        var category: String
        var status: FallbackCredentialDraftStatus

        init(code: String, name: String, expiresAt: Int, active: Bool, diagnosisCode: String, archived: Bool, limit: Int, timezone: String, score: Double, procedureCode: String, category: String, status: FallbackCredentialDraftStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.active = active
            self.diagnosisCode = diagnosisCode
            self.archived = archived
            self.limit = limit
            self.timezone = timezone
            self.score = score
            self.procedureCode = procedureCode
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackCredentialDraftStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == FallbackCredentialDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCredentialDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback credential draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback credential draft") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(expiresAt) + score) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCredentialDraft {
            return FallbackCredentialDraft(
                code: code,
                name: name,
                expiresAt: expiresAt,
                active: active,
                diagnosisCode: diagnosisCode,
                archived: archived,
                limit: limit,
                timezone: timezone,
                score: score,
                procedureCode: procedureCode,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a fallback credential draft in status created.
    static func newFallbackCredentialDraft(_ code: String, name: String) -> FallbackCredentialDraft {
        return FallbackCredentialDraft(
            code: code,
            name: name,
            expiresAt: 0,
            active: false,
            diagnosisCode: "",
            archived: false,
            limit: 0,
            timezone: "",
            score: 0.0,
            procedureCode: "",
            category: "",
            status: FallbackCredentialDraftStatus.created
        )
    }
}
