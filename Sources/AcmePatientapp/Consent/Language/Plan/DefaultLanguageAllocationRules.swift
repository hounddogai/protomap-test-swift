import AcmePlatform
import Foundation

extension Consent {
    /// A rule a default language allocation must pass. Check returns its problems, or none.
    protocol DefaultLanguageAllocationRule {
        func check(_ item: DefaultLanguageAllocation) -> [String]
    }

    final class DefaultLanguageAllocationSequenceRangeRule: DefaultLanguageAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultLanguageAllocation) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultLanguageAllocationCodeLengthRule: DefaultLanguageAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultLanguageAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultLanguageAllocationRequiredCodeRule: DefaultLanguageAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultLanguageAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultLanguageAllocationRequiredNameRule: DefaultLanguageAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultLanguageAllocation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultLanguageAllocationAllowedCodeRule: DefaultLanguageAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultLanguageAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class DefaultLanguageAllocationLimitRangeRule: DefaultLanguageAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultLanguageAllocation) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a default language allocation.
    final class DefaultLanguageAllocationValidator {
        var rules: [any DefaultLanguageAllocationRule]

        init(rules: [any DefaultLanguageAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultLanguageAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultLanguageAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultLanguageAllocation]) -> [String: [String]] {
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

    static func defaultDefaultLanguageAllocationValidator() -> DefaultLanguageAllocationValidator {
        return DefaultLanguageAllocationValidator(
            rules: [
                DefaultLanguageAllocationSequenceRangeRule(min: 80, max: 255),
                DefaultLanguageAllocationCodeLengthRule(maxLength: 3600),
                DefaultLanguageAllocationRequiredCodeRule(message: "default language allocation needs an entry"),
                DefaultLanguageAllocationRequiredNameRule(message: "default language allocation needs an entry"),
                DefaultLanguageAllocationAllowedCodeRule(allowed: []),
                DefaultLanguageAllocationLimitRangeRule(min: 64, max: 255),
            ]
        )
    }
}
