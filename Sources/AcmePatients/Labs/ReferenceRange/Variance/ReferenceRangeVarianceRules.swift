import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range variance must pass. Check returns its problems, or none.
    protocol ReferenceRangeVarianceRule {
        func check(_ item: ReferenceRangeVariance) -> [String]
    }

    final class ReferenceRangeVarianceRequiredCurrencyRule: ReferenceRangeVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeVariance) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeVarianceRequiredCodeRule: ReferenceRangeVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeVarianceNotesLengthRule: ReferenceRangeVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeVariance) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeVarianceLimitRangeRule: ReferenceRangeVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeVariance) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferenceRangeVarianceTitleLengthRule: ReferenceRangeVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeVarianceCodePrefixRule: ReferenceRangeVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferenceRangeVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range variance.
    final class ReferenceRangeVarianceValidator {
        var rules: [any ReferenceRangeVarianceRule]

        init(rules: [any ReferenceRangeVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeVariance) -> [String] {
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

        func requireValid(_ item: ReferenceRangeVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeVariance]) -> [String: [String]] {
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

    static func defaultReferenceRangeVarianceValidator() -> ReferenceRangeVarianceValidator {
        return ReferenceRangeVarianceValidator(
            rules: [
                ReferenceRangeVarianceRequiredCurrencyRule(message: "reference range variance needs a value"),
                ReferenceRangeVarianceRequiredCodeRule(message: "reference range variance needs this field"),
                ReferenceRangeVarianceNotesLengthRule(maxLength: 64),
                ReferenceRangeVarianceLimitRangeRule(min: 32, max: 64),
                ReferenceRangeVarianceTitleLengthRule(maxLength: 120),
                ReferenceRangeVarianceCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
