import AcmePlatform
import Foundation

extension Consent {
    /// A rule a weighted witness entry must pass. Check returns its problems, or none.
    protocol WeightedWitnessEntryRule {
        func check(_ item: WeightedWitnessEntry) -> [String]
    }

    final class WeightedWitnessEntryCodeLengthRule: WeightedWitnessEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedWitnessEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedWitnessEntryStartsAtRangeRule: WeightedWitnessEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedWitnessEntry) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedWitnessEntryAllowedCodeRule: WeightedWitnessEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedWitnessEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted witness entry.
    final class WeightedWitnessEntryValidator {
        var rules: [any WeightedWitnessEntryRule]

        init(rules: [any WeightedWitnessEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedWitnessEntry) -> [String] {
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

        func requireValid(_ item: WeightedWitnessEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedWitnessEntry]) -> [String: [String]] {
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

    static func defaultWeightedWitnessEntryValidator() -> WeightedWitnessEntryValidator {
        return WeightedWitnessEntryValidator(
            rules: [
                WeightedWitnessEntryCodeLengthRule(maxLength: 64),
                WeightedWitnessEntryStartsAtRangeRule(min: 32, max: 86400),
                WeightedWitnessEntryAllowedCodeRule(allowed: []),
            ]
        )
    }
}
