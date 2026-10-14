import AcmePlatform
import Foundation

extension Consent {
    /// A rule a weighted proxy summary must pass. Check returns its problems, or none.
    protocol WeightedProxySummaryRule {
        func check(_ item: WeightedProxySummary) -> [String]
    }

    final class WeightedProxySummaryCodePrefixRule: WeightedProxySummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedProxySummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedProxySummaryDosageMgRangeRule: WeightedProxySummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedProxySummary) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedProxySummaryNameLengthRule: WeightedProxySummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedProxySummary) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedProxySummaryAllowedCodeRule: WeightedProxySummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedProxySummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class WeightedProxySummaryRequiredNameRule: WeightedProxySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedProxySummary) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted proxy summary.
    final class WeightedProxySummaryValidator {
        var rules: [any WeightedProxySummaryRule]

        init(rules: [any WeightedProxySummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedProxySummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedProxySummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedProxySummary]) -> [String: [String]] {
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

    static func defaultWeightedProxySummaryValidator() -> WeightedProxySummaryValidator {
        return WeightedProxySummaryValidator(
            rules: [
                WeightedProxySummaryCodePrefixRule(prefix: "Q"),
                WeightedProxySummaryDosageMgRangeRule(min: 4.3, max: 327.0),
                WeightedProxySummaryNameLengthRule(maxLength: 255),
                WeightedProxySummaryAllowedCodeRule(allowed: ["regional", "legacy", "global"]),
                WeightedProxySummaryRequiredNameRule(message: "weighted proxy summary needs a value"),
            ]
        )
    }
}
