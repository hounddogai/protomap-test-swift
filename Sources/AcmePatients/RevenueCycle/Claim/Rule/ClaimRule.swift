import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim rule is in its life cycle.
    enum ClaimRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A claim rule as the claim team keeps it.
    final class ClaimRule {
        var code: String
        var title: String
        var locale: String
        var sequence: Int
        var source: String
        var active: Bool
        var startsAt: Int
        var currency: String
        var status: ClaimRuleStatus

        init(code: String, title: String, locale: String, sequence: Int, source: String, active: Bool, startsAt: Int, currency: String, status: ClaimRuleStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.sequence = sequence
            self.source = source
            self.active = active
            self.startsAt = startsAt
            self.currency = currency
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClaimRuleStatus) -> Bool {
            switch status {
            case .new:
                return next == ClaimRuleStatus.failed
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ClaimRuleStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ClaimRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("claim rule") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(startsAt) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimRule {
            return ClaimRule(
                code: code,
                title: title,
                locale: locale,
                sequence: sequence,
                source: source,
                active: active,
                startsAt: startsAt,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a claim rule in status new.
    static func newClaimRule(_ code: String, title: String) -> ClaimRule {
        return ClaimRule(
            code: code,
            title: title,
            locale: "",
            sequence: 0,
            source: "",
            active: false,
            startsAt: 0,
            currency: "",
            status: ClaimRuleStatus.new
        )
    }
}
