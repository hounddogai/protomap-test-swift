import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction score must pass. Check returns its problems, or none.
    protocol InteractionScoreRule {
        func check(_ item: InteractionScore) -> [String]
    }

    final class InteractionScoreCodePrefixRule: InteractionScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InteractionScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InteractionScoreWeightRangeRule: InteractionScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionScore) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InteractionScorePhoneLengthRule: InteractionScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionScore) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionScoreRequiredCodeRule: InteractionScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionScoreCodeLengthRule: InteractionScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction score.
    final class InteractionScoreValidator {
        var rules: [any InteractionScoreRule]

        init(rules: [any InteractionScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionScore]) -> [String: [String]] {
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

    static func defaultInteractionScoreValidator() -> InteractionScoreValidator {
        return InteractionScoreValidator(
            rules: [
                InteractionScoreCodePrefixRule(prefix: "Q"),
                InteractionScoreWeightRangeRule(min: 7.3, max: 2116.9),
                InteractionScorePhoneLengthRule(maxLength: 86400),
                InteractionScoreRequiredCodeRule(message: "interaction score needs a value"),
                InteractionScoreCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
