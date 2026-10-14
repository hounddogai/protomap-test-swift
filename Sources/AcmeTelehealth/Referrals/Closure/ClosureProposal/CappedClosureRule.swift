import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped closure rule is in its life cycle.
    enum CappedClosureRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a capped closure rule and its current status.
    final class CappedClosureRule {
        var code: String
        var label: String
        var encounterID: String
        var source: String
        var timezone: String
        var copay: Double
        var tags: [String]
        var currency: String
        var active: Bool
        var status: CappedClosureRuleStatus

        init(code: String, label: String, encounterID: String, source: String, timezone: String, copay: Double, tags: [String], currency: String, active: Bool, status: CappedClosureRuleStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.source = source
            self.timezone = timezone
            self.copay = copay
            self.tags = tags
            self.currency = currency
            self.active = active
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

        func canMoveTo(_ next: CappedClosureRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CappedClosureRuleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedClosureRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped closure rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> CappedClosureRule {
            return CappedClosureRule(
                code: code,
                label: label,
                encounterID: encounterID,
                source: source,
                timezone: timezone,
                copay: copay,
                tags: tags,
                currency: currency,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a capped closure rule in status new.
    static func newCappedClosureRule(_ code: String, label: String) -> CappedClosureRule {
        return CappedClosureRule(
            code: code,
            label: label,
            encounterID: "",
            source: "",
            timezone: "",
            copay: 0.0,
            tags: [],
            currency: "",
            active: false,
            status: CappedClosureRuleStatus.new
        )
    }
}
