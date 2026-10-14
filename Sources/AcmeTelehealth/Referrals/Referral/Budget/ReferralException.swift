import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral exception is in its life cycle.
    enum ReferralExceptionStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One referral exception, with what the planners need to act on it.
    final class ReferralException {
        var code: String
        var name: String
        var attempts: Int
        var active: Bool
        var tags: [String]
        var notes: String
        var specialty: String
        var revision: Int
        var status: ReferralExceptionStatus

        init(code: String, name: String, attempts: Int, active: Bool, tags: [String], notes: String, specialty: String, revision: Int, status: ReferralExceptionStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.active = active
            self.tags = tags
            self.notes = notes
            self.specialty = specialty
            self.revision = revision
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

        func canMoveTo(_ next: ReferralExceptionStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ReferralExceptionStatus.reopened
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ReferralExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedValue() -> Double {
            return ((Double(attempts) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ReferralException {
            return ReferralException(
                code: code,
                name: name,
                attempts: attempts,
                active: active,
                tags: tags,
                notes: notes,
                specialty: specialty,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a referral exception in status open.
    static func newReferralException(_ code: String, name: String) -> ReferralException {
        return ReferralException(
            code: code,
            name: name,
            attempts: 0,
            active: false,
            tags: [],
            notes: "",
            specialty: "",
            revision: 0,
            status: ReferralExceptionStatus.`open`
        )
    }
}
