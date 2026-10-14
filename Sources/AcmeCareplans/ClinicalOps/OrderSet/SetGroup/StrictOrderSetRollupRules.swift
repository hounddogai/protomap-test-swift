import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict order set rollup must pass. Check returns its problems, or none.
    protocol StrictOrderSetRollupRule {
        func check(_ item: StrictOrderSetRollup) -> [String]
    }

    final class StrictOrderSetRollupRequiredCodeRule: StrictOrderSetRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictOrderSetRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictOrderSetRollupCopayRangeRule: StrictOrderSetRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictOrderSetRollup) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictOrderSetRollupCodeLengthRule: StrictOrderSetRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictOrderSetRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictOrderSetRollupRequiredLabelRule: StrictOrderSetRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictOrderSetRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict order set rollup.
    final class StrictOrderSetRollupValidator {
        var rules: [any StrictOrderSetRollupRule]

        init(rules: [any StrictOrderSetRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictOrderSetRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictOrderSetRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictOrderSetRollup]) -> [String: [String]] {
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

    static func defaultStrictOrderSetRollupValidator() -> StrictOrderSetRollupValidator {
        return StrictOrderSetRollupValidator(
            rules: [
                StrictOrderSetRollupRequiredCodeRule(message: "strict order set rollup needs a value"),
                StrictOrderSetRollupCopayRangeRule(min: 4.4, max: 101.8),
                StrictOrderSetRollupCodeLengthRule(maxLength: 3600),
                StrictOrderSetRollupRequiredLabelRule(message: "strict order set rollup needs this field"),
            ]
        )
    }
}
