import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language cycle must pass. Check returns its problems, or none.
    protocol LanguageCycleRule {
        func check(_ item: LanguageCycle) -> [String]
    }

    final class LanguageCycleBudgetRangeRule: LanguageCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageCycle) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageCycleLabelLengthRule: LanguageCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageCycle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageCycleChecksumLengthRule: LanguageCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageCycle) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageCycleRequiredChecksumRule: LanguageCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageCycle) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageCycleAllowedChecksumRule: LanguageCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LanguageCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a language cycle.
    final class LanguageCycleValidator {
        var rules: [any LanguageCycleRule]

        init(rules: [any LanguageCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageCycle]) -> [String: [String]] {
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

    static func defaultLanguageCycleValidator() -> LanguageCycleValidator {
        return LanguageCycleValidator(
            rules: [
                LanguageCycleBudgetRangeRule(min: 5.4, max: 1500.1),
                LanguageCycleLabelLengthRule(maxLength: 32),
                LanguageCycleChecksumLengthRule(maxLength: 1000),
                LanguageCycleRequiredChecksumRule(message: "language cycle needs this field"),
                LanguageCycleAllowedChecksumRule(allowed: []),
            ]
        )
    }
}
