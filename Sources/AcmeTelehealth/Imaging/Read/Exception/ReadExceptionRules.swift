import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read exception must pass. Check returns its problems, or none.
    protocol ReadExceptionRule {
        func check(_ item: ReadException) -> [String]
    }

    final class ReadExceptionWeightRangeRule: ReadExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadException) -> [String] {
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

    final class ReadExceptionCodePrefixRule: ReadExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReadException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReadExceptionRequiredLabelRule: ReadExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadException) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadExceptionCountryLengthRule: ReadExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadException) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a read exception.
    final class ReadExceptionValidator {
        var rules: [any ReadExceptionRule]

        init(rules: [any ReadExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadException]) -> [String: [String]] {
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

    static func defaultReadExceptionValidator() -> ReadExceptionValidator {
        return ReadExceptionValidator(
            rules: [
                ReadExceptionWeightRangeRule(min: 1.9, max: 4001.9),
                ReadExceptionCodePrefixRule(prefix: "ACM"),
                ReadExceptionRequiredLabelRule(message: "read exception needs this field"),
                ReadExceptionCountryLengthRule(maxLength: 16),
            ]
        )
    }
}
