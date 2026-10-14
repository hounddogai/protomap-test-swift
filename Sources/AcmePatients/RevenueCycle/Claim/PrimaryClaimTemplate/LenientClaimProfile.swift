import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient claim profile is in its life cycle.
    enum LenientClaimProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient claim profile as the claim team keeps it.
    final class LenientClaimProfile {
        var code: String
        var title: String
        var limit: Int
        var archived: Bool
        var acuity: Int
        var status: LenientClaimProfileStatus

        init(code: String, title: String, limit: Int, archived: Bool, acuity: Int, status: LenientClaimProfileStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.archived = archived
            self.acuity = acuity
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

        func canMoveTo(_ next: LenientClaimProfileStatus) -> Bool {
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
                return next == LenientClaimProfileStatus.active
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == LenientClaimProfileStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientClaimProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient claim profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient claim profile") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(limit) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> LenientClaimProfile {
            return LenientClaimProfile(
                code: code,
                title: title,
                limit: limit,
                archived: archived,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient claim profile in status draft.
    static func newLenientClaimProfile(_ code: String, title: String) -> LenientClaimProfile {
        return LenientClaimProfile(
            code: code,
            title: title,
            limit: 0,
            archived: false,
            acuity: 0,
            status: LenientClaimProfileStatus.draft
        )
    }
}
