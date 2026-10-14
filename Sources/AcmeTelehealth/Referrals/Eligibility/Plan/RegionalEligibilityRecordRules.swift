import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional eligibility record must pass. Check returns its problems, or none.
    protocol RegionalEligibilityRecordRule {
        func check(_ item: RegionalEligibilityRecord) -> [String]
    }

    final class RegionalEligibilityRecordLabelLengthRule: RegionalEligibilityRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalEligibilityRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalEligibilityRecordRequiredLabelRule: RegionalEligibilityRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalEligibilityRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalEligibilityRecordDiscountRangeRule: RegionalEligibilityRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalEligibilityRecord) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalEligibilityRecordRequiredCategoryRule: RegionalEligibilityRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalEligibilityRecord) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalEligibilityRecordCodePrefixRule: RegionalEligibilityRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalEligibilityRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional eligibility record.
    final class RegionalEligibilityRecordValidator {
        var rules: [any RegionalEligibilityRecordRule]

        init(rules: [any RegionalEligibilityRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalEligibilityRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalEligibilityRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalEligibilityRecord]) -> [String: [String]] {
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

    static func defaultRegionalEligibilityRecordValidator() -> RegionalEligibilityRecordValidator {
        return RegionalEligibilityRecordValidator(
            rules: [
                RegionalEligibilityRecordLabelLengthRule(maxLength: 120),
                RegionalEligibilityRecordRequiredLabelRule(message: "regional eligibility record needs this field"),
                RegionalEligibilityRecordDiscountRangeRule(min: 5.7, max: 638.9),
                RegionalEligibilityRecordRequiredCategoryRule(message: "regional eligibility record needs a value"),
                RegionalEligibilityRecordCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
