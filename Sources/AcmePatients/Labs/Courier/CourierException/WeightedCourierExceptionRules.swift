import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted courier exception must pass. Check returns its problems, or none.
    protocol WeightedCourierExceptionRule {
        func check(_ item: WeightedCourierException) -> [String]
    }

    final class WeightedCourierExceptionRequiredChecksumRule: WeightedCourierExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCourierException) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCourierExceptionChecksumLengthRule: WeightedCourierExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCourierException) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCourierExceptionCurrencyLengthRule: WeightedCourierExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCourierException) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCourierExceptionRequiredCurrencyRule: WeightedCourierExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCourierException) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted courier exception.
    final class WeightedCourierExceptionValidator {
        var rules: [any WeightedCourierExceptionRule]

        init(rules: [any WeightedCourierExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCourierException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedCourierException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCourierException]) -> [String: [String]] {
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

    static func defaultWeightedCourierExceptionValidator() -> WeightedCourierExceptionValidator {
        return WeightedCourierExceptionValidator(
            rules: [
                WeightedCourierExceptionRequiredChecksumRule(message: "weighted courier exception needs this field"),
                WeightedCourierExceptionChecksumLengthRule(maxLength: 3600),
                WeightedCourierExceptionCurrencyLengthRule(maxLength: 64),
                WeightedCourierExceptionRequiredCurrencyRule(message: "weighted courier exception needs this field"),
            ]
        )
    }
}
