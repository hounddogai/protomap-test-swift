import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge baseline must pass. Check returns its problems, or none.
    protocol ChargeBaselineRule {
        func check(_ item: ChargeBaseline) -> [String]
    }

    final class ChargeBaselineVersionRangeRule: ChargeBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeBaseline) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ChargeBaselineRequiredNameRule: ChargeBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeBaselineCodeLengthRule: ChargeBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge baseline.
    final class ChargeBaselineValidator {
        var rules: [any ChargeBaselineRule]

        init(rules: [any ChargeBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeBaseline]) -> [String: [String]] {
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

    static func defaultChargeBaselineValidator() -> ChargeBaselineValidator {
        return ChargeBaselineValidator(
            rules: [
                ChargeBaselineVersionRangeRule(min: 80, max: 1000),
                ChargeBaselineRequiredNameRule(message: "charge baseline needs a value"),
                ChargeBaselineCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
