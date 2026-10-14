import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation exception must pass. Check returns its problems, or none.
    protocol RevocationExceptionRule {
        func check(_ item: RevocationException) -> [String]
    }

    final class RevocationExceptionMinimumRangeRule: RevocationExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationException) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RevocationExceptionNameLengthRule: RevocationExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationException) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationExceptionRequiredSpecialtyRule: RevocationExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationException) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationExceptionSpecialtyLengthRule: RevocationExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationException) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation exception.
    final class RevocationExceptionValidator {
        var rules: [any RevocationExceptionRule]

        init(rules: [any RevocationExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationException) -> [String] {
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

        func requireValid(_ item: RevocationException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationException]) -> [String: [String]] {
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

    static func defaultRevocationExceptionValidator() -> RevocationExceptionValidator {
        return RevocationExceptionValidator(
            rules: [
                RevocationExceptionMinimumRangeRule(min: 6.6, max: 2848.0),
                RevocationExceptionNameLengthRule(maxLength: 1000),
                RevocationExceptionRequiredSpecialtyRule(message: "revocation exception needs a value"),
                RevocationExceptionSpecialtyLengthRule(maxLength: 86400),
            ]
        )
    }
}
