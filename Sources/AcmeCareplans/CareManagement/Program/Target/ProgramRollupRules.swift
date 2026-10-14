import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program rollup must pass. Check returns its problems, or none.
    protocol ProgramRollupRule {
        func check(_ item: ProgramRollup) -> [String]
    }

    final class ProgramRollupCategoryLengthRule: ProgramRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramRollup) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramRollupAllowedBedRule: ProgramRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProgramRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is unknown"]
            }
            return []
        }
    }

    final class ProgramRollupRequiredCategoryRule: ProgramRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramRollup) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramRollupRatioRangeRule: ProgramRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramRollup) -> [String] {
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

    /// Runs every rule of a program rollup.
    final class ProgramRollupValidator {
        var rules: [any ProgramRollupRule]

        init(rules: [any ProgramRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramRollup]) -> [String: [String]] {
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

    static func defaultProgramRollupValidator() -> ProgramRollupValidator {
        return ProgramRollupValidator(
            rules: [
                ProgramRollupCategoryLengthRule(maxLength: 32),
                ProgramRollupAllowedBedRule(allowed: ["strict", "rolling", "default"]),
                ProgramRollupRequiredCategoryRule(message: "program rollup needs a value"),
                ProgramRollupRatioRangeRule(min: 1.5, max: 4835.7),
            ]
        )
    }
}
