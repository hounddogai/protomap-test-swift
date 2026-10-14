import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted formulary rollup must pass. Check returns its problems, or none.
    protocol WeightedFormularyRollupRule {
        func check(_ item: WeightedFormularyRollup) -> [String]
    }

    final class WeightedFormularyRollupRequiredCodeRule: WeightedFormularyRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFormularyRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFormularyRollupNameLengthRule: WeightedFormularyRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedFormularyRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedFormularyRollupRequiredNameRule: WeightedFormularyRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFormularyRollup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted formulary rollup.
    final class WeightedFormularyRollupValidator {
        var rules: [any WeightedFormularyRollupRule]

        init(rules: [any WeightedFormularyRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedFormularyRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedFormularyRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedFormularyRollup]) -> [String: [String]] {
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

    static func defaultWeightedFormularyRollupValidator() -> WeightedFormularyRollupValidator {
        return WeightedFormularyRollupValidator(
            rules: [
                WeightedFormularyRollupRequiredCodeRule(message: "weighted formulary rollup needs this field"),
                WeightedFormularyRollupNameLengthRule(maxLength: 32),
                WeightedFormularyRollupRequiredNameRule(message: "weighted formulary rollup needs this field"),
            ]
        )
    }
}
