import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy plan must pass. Check returns its problems, or none.
    protocol ProxyPlanRule {
        func check(_ item: ProxyPlan) -> [String]
    }

    final class ProxyPlanRequiredReviewerRule: ProxyPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyPlan) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyPlanPayerLengthRule: ProxyPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyPlan) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyPlanVisibleGuardRule: ProxyPlanRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ProxyPlan) -> [String] {
            if item.visible && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ProxyPlanRequiredCodeRule: ProxyPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyPlanRequiredPayerRule: ProxyPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyPlan) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyPlanAllowedTitleRule: ProxyPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy plan.
    final class ProxyPlanValidator {
        var rules: [any ProxyPlanRule]

        init(rules: [any ProxyPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyPlan) -> [String] {
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

        func requireValid(_ item: ProxyPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyPlan]) -> [String: [String]] {
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

    static func defaultProxyPlanValidator() -> ProxyPlanValidator {
        return ProxyPlanValidator(
            rules: [
                ProxyPlanRequiredReviewerRule(message: "proxy plan needs a value"),
                ProxyPlanPayerLengthRule(maxLength: 1000),
                ProxyPlanVisibleGuardRule(limit: 4.5),
                ProxyPlanRequiredCodeRule(message: "proxy plan needs a value"),
                ProxyPlanRequiredPayerRule(message: "proxy plan needs a value"),
                ProxyPlanAllowedTitleRule(allowed: []),
            ]
        )
    }
}
