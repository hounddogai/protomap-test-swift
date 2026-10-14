import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global substitution score is in its life cycle.
    enum GlobalSubstitutionScoreStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One global substitution score, with what the planners need to act on it.
    final class GlobalSubstitutionScore {
        var code: String
        var title: String
        var score: Double
        var contactEmail: String
        var currency: String
        var archived: Bool
        var expiresAt: Int
        var checksum: String
        var status: GlobalSubstitutionScoreStatus

        init(code: String, title: String, score: Double, contactEmail: String, currency: String, archived: Bool, expiresAt: Int, checksum: String, status: GlobalSubstitutionScoreStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.contactEmail = contactEmail
            self.currency = currency
            self.archived = archived
            self.expiresAt = expiresAt
            self.checksum = checksum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalSubstitutionScoreStatus) -> Bool {
            switch status {
            case .idle:
                return next == GlobalSubstitutionScoreStatus.warming
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == GlobalSubstitutionScoreStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: GlobalSubstitutionScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global substitution score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("global substitution score") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(expiresAt) - score) * 100).rounded() / 100
        }

        func copyValue() -> GlobalSubstitutionScore {
            return GlobalSubstitutionScore(
                code: code,
                title: title,
                score: score,
                contactEmail: contactEmail,
                currency: currency,
                archived: archived,
                expiresAt: expiresAt,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global substitution score in status idle.
    static func newGlobalSubstitutionScore(_ code: String, title: String) -> GlobalSubstitutionScore {
        return GlobalSubstitutionScore(
            code: code,
            title: title,
            score: 0.0,
            contactEmail: "",
            currency: "",
            archived: false,
            expiresAt: 0,
            checksum: "",
            status: GlobalSubstitutionScoreStatus.idle
        )
    }
}
