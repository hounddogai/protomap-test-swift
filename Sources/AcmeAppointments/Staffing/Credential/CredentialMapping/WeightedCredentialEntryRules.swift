import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a weighted credential entry must pass. Check returns its problems, or none.
    protocol WeightedCredentialEntryRule {
        func check(_ item: WeightedCredentialEntry) -> [String]
    }

    final class WeightedCredentialEntryCodeLengthRule: WeightedCredentialEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCredentialEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCredentialEntryRequiredDescriptionRule: WeightedCredentialEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCredentialEntry) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCredentialEntrySequenceRangeRule: WeightedCredentialEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCredentialEntry) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedCredentialEntryRequiredCodeRule: WeightedCredentialEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCredentialEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCredentialEntryRefillsRangeRule: WeightedCredentialEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCredentialEntry) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a weighted credential entry.
    final class WeightedCredentialEntryValidator {
        var rules: [any WeightedCredentialEntryRule]

        init(rules: [any WeightedCredentialEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCredentialEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedCredentialEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCredentialEntry]) -> [String: [String]] {
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

    static func defaultWeightedCredentialEntryValidator() -> WeightedCredentialEntryValidator {
        return WeightedCredentialEntryValidator(
            rules: [
                WeightedCredentialEntryCodeLengthRule(maxLength: 120),
                WeightedCredentialEntryRequiredDescriptionRule(message: "weighted credential entry needs a value"),
                WeightedCredentialEntrySequenceRangeRule(min: 80, max: 1000),
                WeightedCredentialEntryRequiredCodeRule(message: "weighted credential entry needs an entry"),
                WeightedCredentialEntryRefillsRangeRule(min: 16, max: 120),
            ]
        )
    }
}
