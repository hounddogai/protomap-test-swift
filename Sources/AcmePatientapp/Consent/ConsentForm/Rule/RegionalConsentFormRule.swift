import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional consent form rule is in its life cycle.
    enum RegionalConsentFormRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a regional consent form rule and its current status.
    final class RegionalConsentFormRule {
        var code: String
        var name: String
        var limit: Int
        var pinned: Bool
        var locale: String
        var budget: Double
        var floorValue: Double
        var status: RegionalConsentFormRuleStatus

        init(code: String, name: String, limit: Int, pinned: Bool, locale: String, budget: Double, floorValue: Double, status: RegionalConsentFormRuleStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.pinned = pinned
            self.locale = locale
            self.budget = budget
            self.floorValue = floorValue
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

        func canMoveTo(_ next: RegionalConsentFormRuleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalConsentFormRuleStatus.resolved || next == RegionalConsentFormRuleStatus.reopened
            case .inReview:
                return next == RegionalConsentFormRuleStatus.resolved || next == RegionalConsentFormRuleStatus.archived
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: RegionalConsentFormRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional consent form rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netVolume() -> Double {
            return (floorValue * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> RegionalConsentFormRule {
            return RegionalConsentFormRule(
                code: code,
                name: name,
                limit: limit,
                pinned: pinned,
                locale: locale,
                budget: budget,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a regional consent form rule in status open.
    static func newRegionalConsentFormRule(_ code: String, name: String) -> RegionalConsentFormRule {
        return RegionalConsentFormRule(
            code: code,
            name: name,
            limit: 0,
            pinned: false,
            locale: "",
            budget: 0.0,
            floorValue: 0.0,
            status: RegionalConsentFormRuleStatus.`open`
        )
    }
}
