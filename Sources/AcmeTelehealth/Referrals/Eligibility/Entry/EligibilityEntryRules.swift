import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility entry must pass. Check returns its problems, or none.
    protocol EligibilityEntryRule {
        func check(_ item: EligibilityEntry) -> [String]
    }

    final class EligibilityEntryLabelLengthRule: EligibilityEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityEntry) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityEntryMaximumRangeRule: EligibilityEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityEntry) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class EligibilityEntryCodeLengthRule: EligibilityEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility entry.
    final class EligibilityEntryValidator {
        var rules: [any EligibilityEntryRule]

        init(rules: [any EligibilityEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilityEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityEntry]) -> [String: [String]] {
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

    static func defaultEligibilityEntryValidator() -> EligibilityEntryValidator {
        return EligibilityEntryValidator(
            rules: [
                EligibilityEntryLabelLengthRule(maxLength: 3600),
                EligibilityEntryMaximumRangeRule(min: 7.2, max: 1246.5),
                EligibilityEntryCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
