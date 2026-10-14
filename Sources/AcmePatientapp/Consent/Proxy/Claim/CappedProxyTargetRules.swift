import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped proxy target must pass. Check returns its problems, or none.
    protocol CappedProxyTargetRule {
        func check(_ item: CappedProxyTarget) -> [String]
    }

    final class CappedProxyTargetTimezoneLengthRule: CappedProxyTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedProxyTarget) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedProxyTargetRequiredTimezoneRule: CappedProxyTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedProxyTarget) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedProxyTargetPriorityRangeRule: CappedProxyTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedProxyTarget) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped proxy target.
    final class CappedProxyTargetValidator {
        var rules: [any CappedProxyTargetRule]

        init(rules: [any CappedProxyTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedProxyTarget) -> [String] {
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

        func requireValid(_ item: CappedProxyTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedProxyTarget]) -> [String: [String]] {
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

    static func defaultCappedProxyTargetValidator() -> CappedProxyTargetValidator {
        return CappedProxyTargetValidator(
            rules: [
                CappedProxyTargetTimezoneLengthRule(maxLength: 86400),
                CappedProxyTargetRequiredTimezoneRule(message: "capped proxy target needs a value"),
                CappedProxyTargetPriorityRangeRule(min: 32, max: 3600),
            ]
        )
    }
}
