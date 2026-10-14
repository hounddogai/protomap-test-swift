import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling witness entry must pass. Check returns its problems, or none.
    protocol RollingWitnessEntryRule {
        func check(_ item: RollingWitnessEntry) -> [String]
    }

    final class RollingWitnessEntryRequiredNotesRule: RollingWitnessEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingWitnessEntry) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingWitnessEntryCodePrefixRule: RollingWitnessEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingWitnessEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingWitnessEntryMaximumRangeRule: RollingWitnessEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingWitnessEntry) -> [String] {
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

    final class RollingWitnessEntryNotesLengthRule: RollingWitnessEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingWitnessEntry) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling witness entry.
    final class RollingWitnessEntryValidator {
        var rules: [any RollingWitnessEntryRule]

        init(rules: [any RollingWitnessEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingWitnessEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingWitnessEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingWitnessEntry]) -> [String: [String]] {
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

    static func defaultRollingWitnessEntryValidator() -> RollingWitnessEntryValidator {
        return RollingWitnessEntryValidator(
            rules: [
                RollingWitnessEntryRequiredNotesRule(message: "rolling witness entry needs this field"),
                RollingWitnessEntryCodePrefixRule(prefix: "REF"),
                RollingWitnessEntryMaximumRangeRule(min: 8.8, max: 1877.1),
                RollingWitnessEntryNotesLengthRule(maxLength: 255),
            ]
        )
    }
}
