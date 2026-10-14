import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy group must pass. Check returns its problems, or none.
    protocol ProxyGroupRule {
        func check(_ item: ProxyGroup) -> [String]
    }

    final class ProxyGroupNameLengthRule: ProxyGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyGroupDosageMgRangeRule: ProxyGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyGroup) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProxyGroupRequiredNameRule: ProxyGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyGroup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy group.
    final class ProxyGroupValidator {
        var rules: [any ProxyGroupRule]

        init(rules: [any ProxyGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyGroup]) -> [String: [String]] {
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

    static func defaultProxyGroupValidator() -> ProxyGroupValidator {
        return ProxyGroupValidator(
            rules: [
                ProxyGroupNameLengthRule(maxLength: 16),
                ProxyGroupDosageMgRangeRule(min: 7.7, max: 465.1),
                ProxyGroupRequiredNameRule(message: "proxy group needs this field"),
            ]
        )
    }
}
