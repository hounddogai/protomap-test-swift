import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form rollup must pass. Check returns its problems, or none.
    protocol ConsentFormRollupRule {
        func check(_ item: ConsentFormRollup) -> [String]
    }

    final class ConsentFormRollupRequiredCodeRule: ConsentFormRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormRollupRequiredLabelRule: ConsentFormRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormRollupLabelLengthRule: ConsentFormRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormRollupCostRangeRule: ConsentFormRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormRollup) -> [String] {
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

    /// Runs every rule of a consent form rollup.
    final class ConsentFormRollupValidator {
        var rules: [any ConsentFormRollupRule]

        init(rules: [any ConsentFormRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormRollup) -> [String] {
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

        func requireValid(_ item: ConsentFormRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormRollup]) -> [String: [String]] {
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

    static func defaultConsentFormRollupValidator() -> ConsentFormRollupValidator {
        return ConsentFormRollupValidator(
            rules: [
                ConsentFormRollupRequiredCodeRule(message: "consent form rollup needs a value"),
                ConsentFormRollupRequiredLabelRule(message: "consent form rollup needs this field"),
                ConsentFormRollupLabelLengthRule(maxLength: 32),
                ConsentFormRollupCostRangeRule(min: 0.2, max: 109.8),
            ]
        )
    }
}
