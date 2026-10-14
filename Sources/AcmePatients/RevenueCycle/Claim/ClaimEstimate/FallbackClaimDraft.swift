import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback claim draft is in its life cycle.
    enum FallbackClaimDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One fallback claim draft, with what the planners need to act on it.
    final class FallbackClaimDraft {
        var code: String
        var title: String
        var quantity: Int
        var durationMinutes: Int
        var startsAt: Int
        var status: FallbackClaimDraftStatus

        init(code: String, title: String, quantity: Int, durationMinutes: Int, startsAt: Int, status: FallbackClaimDraftStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.durationMinutes = durationMinutes
            self.startsAt = startsAt
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

        func canMoveTo(_ next: FallbackClaimDraftStatus) -> Bool {
            switch status {
            case .draft:
                return next == FallbackClaimDraftStatus.suspended || next == FallbackClaimDraftStatus.closed
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == FallbackClaimDraftStatus.suspended || next == FallbackClaimDraftStatus.closed
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

        func moveTo(_ next: FallbackClaimDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback claim draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveLoad() -> Double {
            return ((Double(startsAt) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackClaimDraft {
            return FallbackClaimDraft(
                code: code,
                title: title,
                quantity: quantity,
                durationMinutes: durationMinutes,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback claim draft in status draft.
    static func newFallbackClaimDraft(_ code: String, title: String) -> FallbackClaimDraft {
        return FallbackClaimDraft(
            code: code,
            title: title,
            quantity: 0,
            durationMinutes: 0,
            startsAt: 0,
            status: FallbackClaimDraftStatus.draft
        )
    }
}
