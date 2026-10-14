import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge variance must pass. Check returns its problems, or none.
    protocol ChargeVarianceRule {
        func check(_ item: ChargeVariance) -> [String]
    }

    final class ChargeVarianceContactEmailLengthRule: ChargeVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeVariance) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeVarianceWindowDaysRangeRule: ChargeVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeVariance) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeVarianceCreatedAtRangeRule: ChargeVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeVariance) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeVarianceRequiredTitleRule: ChargeVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a charge variance.
    final class ChargeVarianceValidator {
        var rules: [any ChargeVarianceRule]

        init(rules: [any ChargeVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeVariance]) -> [String: [String]] {
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

    static func defaultChargeVarianceValidator() -> ChargeVarianceValidator {
        return ChargeVarianceValidator(
            rules: [
                ChargeVarianceContactEmailLengthRule(maxLength: 120),
                ChargeVarianceWindowDaysRangeRule(min: 16, max: 3600),
                ChargeVarianceCreatedAtRangeRule(min: 16, max: 3600),
                ChargeVarianceRequiredTitleRule(message: "charge variance needs an entry"),
            ]
        )
    }
}
