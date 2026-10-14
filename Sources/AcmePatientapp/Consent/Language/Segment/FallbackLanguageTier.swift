import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback language tier is in its life cycle.
    enum FallbackLanguageTierStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback language tier as the language team keeps it.
    final class FallbackLanguageTier {
        var code: String
        var title: String
        var budget: Double
        var channel: String
        var currency: String
        var status: FallbackLanguageTierStatus

        init(code: String, title: String, budget: Double, channel: String, currency: String, status: FallbackLanguageTierStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.channel = channel
            self.currency = currency
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

        func canMoveTo(_ next: FallbackLanguageTierStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackLanguageTierStatus.ready
            case .warming:
                return next == FallbackLanguageTierStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == FallbackLanguageTierStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackLanguageTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback language tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> FallbackLanguageTier {
            return FallbackLanguageTier(
                code: code,
                title: title,
                budget: budget,
                channel: channel,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a fallback language tier in status idle.
    static func newFallbackLanguageTier(_ code: String, title: String) -> FallbackLanguageTier {
        return FallbackLanguageTier(
            code: code,
            title: title,
            budget: 0.0,
            channel: "",
            currency: "",
            status: FallbackLanguageTierStatus.idle
        )
    }
}
