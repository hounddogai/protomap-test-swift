import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient claim template must pass. Check returns its problems, or none.
    protocol LenientClaimTemplateRule {
        func check(_ item: LenientClaimTemplate) -> [String]
    }

    final class LenientClaimTemplateNameLengthRule: LenientClaimTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientClaimTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientClaimTemplateCodePrefixRule: LenientClaimTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientClaimTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientClaimTemplateAmountRangeRule: LenientClaimTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientClaimTemplate) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientClaimTemplateRequiredRegionRule: LenientClaimTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientClaimTemplate) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient claim template.
    final class LenientClaimTemplateValidator {
        var rules: [any LenientClaimTemplateRule]

        init(rules: [any LenientClaimTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientClaimTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientClaimTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientClaimTemplate]) -> [String: [String]] {
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

    static func defaultLenientClaimTemplateValidator() -> LenientClaimTemplateValidator {
        return LenientClaimTemplateValidator(
            rules: [
                LenientClaimTemplateNameLengthRule(maxLength: 1000),
                LenientClaimTemplateCodePrefixRule(prefix: "Q"),
                LenientClaimTemplateAmountRangeRule(min: 2.7, max: 2418.4),
                LenientClaimTemplateRequiredRegionRule(message: "lenient claim template needs an entry"),
            ]
        )
    }
}
