import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form exception must pass. Check returns its problems, or none.
    protocol ConsentFormExceptionRule {
        func check(_ item: ConsentFormException) -> [String]
    }

    final class ConsentFormExceptionWeightRangeRule: ConsentFormExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormException) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ConsentFormExceptionLocaleLengthRule: ConsentFormExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormException) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormExceptionRequiredPayerRule: ConsentFormExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormException) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormExceptionCodeLengthRule: ConsentFormExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormExceptionCreatedAtRangeRule: ConsentFormExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormException) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form exception.
    final class ConsentFormExceptionValidator {
        var rules: [any ConsentFormExceptionRule]

        init(rules: [any ConsentFormExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormException) -> [String] {
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

        func requireValid(_ item: ConsentFormException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormException]) -> [String: [String]] {
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

    static func defaultConsentFormExceptionValidator() -> ConsentFormExceptionValidator {
        return ConsentFormExceptionValidator(
            rules: [
                ConsentFormExceptionWeightRangeRule(min: 4.5, max: 3359.3),
                ConsentFormExceptionLocaleLengthRule(maxLength: 255),
                ConsentFormExceptionRequiredPayerRule(message: "consent form exception needs this field"),
                ConsentFormExceptionCodeLengthRule(maxLength: 3600),
                ConsentFormExceptionCreatedAtRangeRule(min: 32, max: 64),
            ]
        )
    }
}
