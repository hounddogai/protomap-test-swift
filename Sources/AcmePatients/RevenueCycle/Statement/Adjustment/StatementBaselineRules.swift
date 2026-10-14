import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement baseline must pass. Check returns its problems, or none.
    protocol StatementBaselineRule {
        func check(_ item: StatementBaseline) -> [String]
    }

    final class StatementBaselineRatioRangeRule: StatementBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementBaseline) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementBaselineTitleLengthRule: StatementBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementBaseline) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementBaselineRequiredSpecialtyRule: StatementBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementBaseline) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementBaselineRequiredNameRule: StatementBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementBaselineSpecialtyLengthRule: StatementBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementBaseline) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementBaselineWeightRangeRule: StatementBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementBaseline) -> [String] {
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

    /// Runs every rule of a statement baseline.
    final class StatementBaselineValidator {
        var rules: [any StatementBaselineRule]

        init(rules: [any StatementBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementBaseline) -> [String] {
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

        func requireValid(_ item: StatementBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementBaseline]) -> [String: [String]] {
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

    static func defaultStatementBaselineValidator() -> StatementBaselineValidator {
        return StatementBaselineValidator(
            rules: [
                StatementBaselineRatioRangeRule(min: 2.8, max: 2297.4),
                StatementBaselineTitleLengthRule(maxLength: 80),
                StatementBaselineRequiredSpecialtyRule(message: "statement baseline needs this field"),
                StatementBaselineRequiredNameRule(message: "statement baseline needs this field"),
                StatementBaselineSpecialtyLengthRule(maxLength: 32),
                StatementBaselineWeightRangeRule(min: 1.4, max: 1680.4),
            ]
        )
    }
}
