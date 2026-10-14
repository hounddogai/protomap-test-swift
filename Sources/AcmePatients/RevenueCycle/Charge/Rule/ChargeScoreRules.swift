import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge score must pass. Check returns its problems, or none.
    protocol ChargeScoreRule {
        func check(_ item: ChargeScore) -> [String]
    }

    final class ChargeScoreCostRangeRule: ChargeScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeScore) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ChargeScoreRequiredTitleRule: ChargeScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeScoreTitleLengthRule: ChargeScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeScoreAcuityRangeRule: ChargeScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeScore) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ChargeScoreAllowedCodeRule: ChargeScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ChargeScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class ChargeScoreRequiredCodeRule: ChargeScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a charge score.
    final class ChargeScoreValidator {
        var rules: [any ChargeScoreRule]

        init(rules: [any ChargeScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeScore]) -> [String: [String]] {
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

    static func defaultChargeScoreValidator() -> ChargeScoreValidator {
        return ChargeScoreValidator(
            rules: [
                ChargeScoreCostRangeRule(min: 1.5, max: 3021.2),
                ChargeScoreRequiredTitleRule(message: "charge score needs an entry"),
                ChargeScoreTitleLengthRule(maxLength: 64),
                ChargeScoreAcuityRangeRule(min: 1000, max: 86400),
                ChargeScoreAllowedCodeRule(allowed: ["adaptive", "weighted", "adaptive"]),
                ChargeScoreRequiredCodeRule(message: "charge score needs this field"),
            ]
        )
    }
}
