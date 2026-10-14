import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding baseline must pass. Check returns its problems, or none.
    protocol RoundingBaselineRule {
        func check(_ item: RoundingBaseline) -> [String]
    }

    final class RoundingBaselineAttemptsRangeRule: RoundingBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingBaseline) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingBaselineApprovedGuardRule: RoundingBaselineRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RoundingBaseline) -> [String] {
            if item.approved && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class RoundingBaselineRequiredNameRule: RoundingBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingBaselineAllowedCodeRule: RoundingBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RoundingBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class RoundingBaselineNameLengthRule: RoundingBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingBaselineCodeLengthRule: RoundingBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding baseline.
    final class RoundingBaselineValidator {
        var rules: [any RoundingBaselineRule]

        init(rules: [any RoundingBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingBaseline) -> [String] {
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

        func requireValid(_ item: RoundingBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingBaseline]) -> [String: [String]] {
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

    static func defaultRoundingBaselineValidator() -> RoundingBaselineValidator {
        return RoundingBaselineValidator(
            rules: [
                RoundingBaselineAttemptsRangeRule(min: 16, max: 64),
                RoundingBaselineApprovedGuardRule(limit: 255),
                RoundingBaselineRequiredNameRule(message: "rounding baseline needs this field"),
                RoundingBaselineAllowedCodeRule(allowed: ["rolling"]),
                RoundingBaselineNameLengthRule(maxLength: 120),
                RoundingBaselineCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
