import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim window must pass. Check returns its problems, or none.
    protocol ClaimWindowRule {
        func check(_ item: ClaimWindow) -> [String]
    }

    final class ClaimWindowRequiredNameRule: ClaimWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimWindow) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimWindowQuantityRangeRule: ClaimWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimWindow) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimWindowAllowedNameRule: ClaimWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class ClaimWindowCodeLengthRule: ClaimWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimWindowLimitRangeRule: ClaimWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimWindow) -> [String] {
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

    final class ClaimWindowScoreRangeRule: ClaimWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimWindow) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a claim window.
    final class ClaimWindowValidator {
        var rules: [any ClaimWindowRule]

        init(rules: [any ClaimWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimWindow]) -> [String: [String]] {
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

    static func defaultClaimWindowValidator() -> ClaimWindowValidator {
        return ClaimWindowValidator(
            rules: [
                ClaimWindowRequiredNameRule(message: "claim window needs an entry"),
                ClaimWindowQuantityRangeRule(min: 64, max: 3600),
                ClaimWindowAllowedNameRule(allowed: ["primary", "scheduled"]),
                ClaimWindowCodeLengthRule(maxLength: 16),
                ClaimWindowLimitRangeRule(min: 16, max: 32),
                ClaimWindowScoreRangeRule(min: 0.0, max: 2104.5),
            ]
        )
    }
}
