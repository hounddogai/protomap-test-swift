import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional witness entry must pass. Check returns its problems, or none.
    protocol RegionalWitnessEntryRule {
        func check(_ item: RegionalWitnessEntry) -> [String]
    }

    final class RegionalWitnessEntryTimezoneLengthRule: RegionalWitnessEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalWitnessEntry) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalWitnessEntryCodeLengthRule: RegionalWitnessEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalWitnessEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalWitnessEntryRateRangeRule: RegionalWitnessEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalWitnessEntry) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalWitnessEntryAllowedCategoryRule: RegionalWitnessEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalWitnessEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a regional witness entry.
    final class RegionalWitnessEntryValidator {
        var rules: [any RegionalWitnessEntryRule]

        init(rules: [any RegionalWitnessEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalWitnessEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalWitnessEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalWitnessEntry]) -> [String: [String]] {
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

    static func defaultRegionalWitnessEntryValidator() -> RegionalWitnessEntryValidator {
        return RegionalWitnessEntryValidator(
            rules: [
                RegionalWitnessEntryTimezoneLengthRule(maxLength: 16),
                RegionalWitnessEntryCodeLengthRule(maxLength: 3600),
                RegionalWitnessEntryRateRangeRule(min: 3.9, max: 3985.5),
                RegionalWitnessEntryAllowedCategoryRule(allowed: ["scheduled", "tiered"]),
            ]
        )
    }
}
