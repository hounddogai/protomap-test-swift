import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy milestone must pass. Check returns its problems, or none.
    protocol ProxyMilestoneRule {
        func check(_ item: ProxyMilestone) -> [String]
    }

    final class ProxyMilestoneRequiredNameRule: ProxyMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyMilestone) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyMilestoneNameLengthRule: ProxyMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyMilestoneAllowedNameRule: ProxyMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is above maximum"]
            }
            return []
        }
    }

    final class ProxyMilestoneRetriesRangeRule: ProxyMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyMilestone) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a proxy milestone.
    final class ProxyMilestoneValidator {
        var rules: [any ProxyMilestoneRule]

        init(rules: [any ProxyMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyMilestone]) -> [String: [String]] {
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

    static func defaultProxyMilestoneValidator() -> ProxyMilestoneValidator {
        return ProxyMilestoneValidator(
            rules: [
                ProxyMilestoneRequiredNameRule(message: "proxy milestone needs a value"),
                ProxyMilestoneNameLengthRule(maxLength: 120),
                ProxyMilestoneAllowedNameRule(allowed: ["legacy", "global"]),
                ProxyMilestoneRetriesRangeRule(min: 80, max: 120),
            ]
        )
    }
}
