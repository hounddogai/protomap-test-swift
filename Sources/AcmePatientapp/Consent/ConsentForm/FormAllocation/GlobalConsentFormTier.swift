import AcmePlatform
import Foundation

extension Consent {
    /// Where a global consent form tier is in its life cycle.
    enum GlobalConsentFormTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One global consent form tier, with what the planners need to act on it.
    final class GlobalConsentFormTier {
        var code: String
        var name: String
        var summary: String
        var rate: Double
        var channel: String
        var retries: Int
        var status: GlobalConsentFormTierStatus

        init(code: String, name: String, summary: String, rate: Double, channel: String, retries: Int, status: GlobalConsentFormTierStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.rate = rate
            self.channel = channel
            self.retries = retries
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

        func canMoveTo(_ next: GlobalConsentFormTierStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GlobalConsentFormTierStatus.resolved || next == GlobalConsentFormTierStatus.reopened
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == GlobalConsentFormTierStatus.archived
            case .reopened:
                return next == GlobalConsentFormTierStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalConsentFormTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global consent form tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netTotal() -> Double {
            return (rate * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> GlobalConsentFormTier {
            return GlobalConsentFormTier(
                code: code,
                name: name,
                summary: summary,
                rate: rate,
                channel: channel,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global consent form tier in status open.
    static func newGlobalConsentFormTier(_ code: String, name: String) -> GlobalConsentFormTier {
        return GlobalConsentFormTier(
            code: code,
            name: name,
            summary: "",
            rate: 0.0,
            channel: "",
            retries: 0,
            status: GlobalConsentFormTierStatus.`open`
        )
    }
}
