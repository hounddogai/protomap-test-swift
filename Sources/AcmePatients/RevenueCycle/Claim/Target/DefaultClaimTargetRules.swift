import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default claim target must pass. Check returns its problems, or none.
    protocol DefaultClaimTargetRule {
        func check(_ item: DefaultClaimTarget) -> [String]
    }

    final class DefaultClaimTargetCodePrefixRule: DefaultClaimTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultClaimTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultClaimTargetCodeLengthRule: DefaultClaimTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultClaimTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultClaimTargetSummaryLengthRule: DefaultClaimTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultClaimTarget) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultClaimTargetAllowedSummaryRule: DefaultClaimTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultClaimTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is expired"]
            }
            return []
        }
    }

    final class DefaultClaimTargetBatchSizeRangeRule: DefaultClaimTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultClaimTarget) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultClaimTargetRequiredCodeRule: DefaultClaimTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultClaimTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default claim target.
    final class DefaultClaimTargetValidator {
        var rules: [any DefaultClaimTargetRule]

        init(rules: [any DefaultClaimTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultClaimTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultClaimTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultClaimTarget]) -> [String: [String]] {
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

    static func defaultDefaultClaimTargetValidator() -> DefaultClaimTargetValidator {
        return DefaultClaimTargetValidator(
            rules: [
                DefaultClaimTargetCodePrefixRule(prefix: "Q"),
                DefaultClaimTargetCodeLengthRule(maxLength: 16),
                DefaultClaimTargetSummaryLengthRule(maxLength: 1000),
                DefaultClaimTargetAllowedSummaryRule(allowed: ["lenient", "strict"]),
                DefaultClaimTargetBatchSizeRangeRule(min: 16, max: 3600),
                DefaultClaimTargetRequiredCodeRule(message: "default claim target needs this field"),
            ]
        )
    }
}
