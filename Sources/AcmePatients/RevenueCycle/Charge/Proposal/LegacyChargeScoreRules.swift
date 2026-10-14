import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy charge score must pass. Check returns its problems, or none.
    protocol LegacyChargeScoreRule {
        func check(_ item: LegacyChargeScore) -> [String]
    }

    final class LegacyChargeScoreNameLengthRule: LegacyChargeScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyChargeScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyChargeScoreCodeLengthRule: LegacyChargeScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyChargeScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyChargeScoreRequiredCodeRule: LegacyChargeScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyChargeScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyChargeScoreAllowedNameRule: LegacyChargeScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyChargeScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is missing"]
            }
            return []
        }
    }

    final class LegacyChargeScoreAttemptsRangeRule: LegacyChargeScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyChargeScore) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyChargeScoreThresholdRangeRule: LegacyChargeScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyChargeScore) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a legacy charge score.
    final class LegacyChargeScoreValidator {
        var rules: [any LegacyChargeScoreRule]

        init(rules: [any LegacyChargeScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyChargeScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyChargeScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyChargeScore]) -> [String: [String]] {
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

    static func defaultLegacyChargeScoreValidator() -> LegacyChargeScoreValidator {
        return LegacyChargeScoreValidator(
            rules: [
                LegacyChargeScoreNameLengthRule(maxLength: 32),
                LegacyChargeScoreCodeLengthRule(maxLength: 16),
                LegacyChargeScoreRequiredCodeRule(message: "legacy charge score needs an entry"),
                LegacyChargeScoreAllowedNameRule(allowed: ["seasonal", "weighted"]),
                LegacyChargeScoreAttemptsRangeRule(min: 32, max: 1000),
                LegacyChargeScoreThresholdRangeRule(min: 9.8, max: 4791.4),
            ]
        )
    }
}
