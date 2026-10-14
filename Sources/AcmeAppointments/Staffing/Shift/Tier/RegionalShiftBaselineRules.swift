import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional shift baseline must pass. Check returns its problems, or none.
    protocol RegionalShiftBaselineRule {
        func check(_ item: RegionalShiftBaseline) -> [String]
    }

    final class RegionalShiftBaselineRequiredCodeRule: RegionalShiftBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalShiftBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalShiftBaselinePayerLengthRule: RegionalShiftBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalShiftBaseline) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalShiftBaselineNameLengthRule: RegionalShiftBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalShiftBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalShiftBaselineWeightRangeRule: RegionalShiftBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalShiftBaseline) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional shift baseline.
    final class RegionalShiftBaselineValidator {
        var rules: [any RegionalShiftBaselineRule]

        init(rules: [any RegionalShiftBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalShiftBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalShiftBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalShiftBaseline]) -> [String: [String]] {
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

    static func defaultRegionalShiftBaselineValidator() -> RegionalShiftBaselineValidator {
        return RegionalShiftBaselineValidator(
            rules: [
                RegionalShiftBaselineRequiredCodeRule(message: "regional shift baseline needs an entry"),
                RegionalShiftBaselinePayerLengthRule(maxLength: 120),
                RegionalShiftBaselineNameLengthRule(maxLength: 3600),
                RegionalShiftBaselineWeightRangeRule(min: 4.3, max: 2259.8),
            ]
        )
    }
}
