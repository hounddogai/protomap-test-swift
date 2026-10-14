import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read rollup must pass. Check returns its problems, or none.
    protocol ReadRollupRule {
        func check(_ item: ReadRollup) -> [String]
    }

    final class ReadRollupDiscountRangeRule: ReadRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadRollup) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReadRollupSequenceRangeRule: ReadRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadRollup) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReadRollupContactEmailLengthRule: ReadRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadRollup) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadRollupRequiredTitleRule: ReadRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadRollupCodeLengthRule: ReadRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a read rollup.
    final class ReadRollupValidator {
        var rules: [any ReadRollupRule]

        init(rules: [any ReadRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadRollup]) -> [String: [String]] {
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

    static func defaultReadRollupValidator() -> ReadRollupValidator {
        return ReadRollupValidator(
            rules: [
                ReadRollupDiscountRangeRule(min: 5.7, max: 4894.0),
                ReadRollupSequenceRangeRule(min: 16, max: 80),
                ReadRollupContactEmailLengthRule(maxLength: 120),
                ReadRollupRequiredTitleRule(message: "read rollup needs this field"),
                ReadRollupCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
