import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback language budget is in its life cycle.
    enum FallbackLanguageBudgetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One fallback language budget, with what the planners need to act on it.
    final class FallbackLanguageBudget {
        var code: String
        var title: String
        var name: String
        var ward: String
        var windowDays: Int
        var channel: String
        var payer: String
        var reviewer: String
        var revision: Int
        var timezone: String
        var status: FallbackLanguageBudgetStatus

        init(code: String, title: String, name: String, ward: String, windowDays: Int, channel: String, payer: String, reviewer: String, revision: Int, timezone: String, status: FallbackLanguageBudgetStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.ward = ward
            self.windowDays = windowDays
            self.channel = channel
            self.payer = payer
            self.reviewer = reviewer
            self.revision = revision
            self.timezone = timezone
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

        func canMoveTo(_ next: FallbackLanguageBudgetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FallbackLanguageBudgetStatus.inReview
            case .inReview:
                return next == FallbackLanguageBudgetStatus.archived
            case .resolved:
                return next == FallbackLanguageBudgetStatus.reopened || next == FallbackLanguageBudgetStatus.archived
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

        func moveTo(_ next: FallbackLanguageBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback language budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedVolume() -> Double {
            return ((Double(windowDays) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackLanguageBudget {
            return FallbackLanguageBudget(
                code: code,
                title: title,
                name: name,
                ward: ward,
                windowDays: windowDays,
                channel: channel,
                payer: payer,
                reviewer: reviewer,
                revision: revision,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback language budget in status open.
    static func newFallbackLanguageBudget(_ code: String, title: String) -> FallbackLanguageBudget {
        return FallbackLanguageBudget(
            code: code,
            title: title,
            name: "",
            ward: "",
            windowDays: 0,
            channel: "",
            payer: "",
            reviewer: "",
            revision: 0,
            timezone: "",
            status: FallbackLanguageBudgetStatus.`open`
        )
    }
}
