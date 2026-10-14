import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled follow up digest must pass. Check returns its problems, or none.
    protocol ScheduledFollowUpDigestRule {
        func check(_ item: ScheduledFollowUpDigest) -> [String]
    }

    final class ScheduledFollowUpDigestDiscountRangeRule: ScheduledFollowUpDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledFollowUpDigest) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledFollowUpDigestRequiredLocaleRule: ScheduledFollowUpDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFollowUpDigest) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledFollowUpDigestRequiredCodeRule: ScheduledFollowUpDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFollowUpDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledFollowUpDigestRequiredLabelRule: ScheduledFollowUpDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFollowUpDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled follow up digest.
    final class ScheduledFollowUpDigestValidator {
        var rules: [any ScheduledFollowUpDigestRule]

        init(rules: [any ScheduledFollowUpDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledFollowUpDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledFollowUpDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledFollowUpDigest]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultScheduledFollowUpDigestValidator() -> ScheduledFollowUpDigestValidator {
        return ScheduledFollowUpDigestValidator(
            rules: [
                ScheduledFollowUpDigestDiscountRangeRule(min: 7.5, max: 1032.7),
                ScheduledFollowUpDigestRequiredLocaleRule(message: "scheduled follow up digest needs a value"),
                ScheduledFollowUpDigestRequiredCodeRule(message: "scheduled follow up digest needs an entry"),
                ScheduledFollowUpDigestRequiredLabelRule(message: "scheduled follow up digest needs an entry"),
            ]
        )
    }
}
