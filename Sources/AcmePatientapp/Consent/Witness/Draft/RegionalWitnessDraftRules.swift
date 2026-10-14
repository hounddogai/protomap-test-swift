import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional witness draft must pass. Check returns its problems, or none.
    protocol RegionalWitnessDraftRule {
        func check(_ item: RegionalWitnessDraft) -> [String]
    }

    final class RegionalWitnessDraftRequiredLabelRule: RegionalWitnessDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalWitnessDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalWitnessDraftCodePrefixRule: RegionalWitnessDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalWitnessDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalWitnessDraftCodeLengthRule: RegionalWitnessDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalWitnessDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalWitnessDraftEndsAtRangeRule: RegionalWitnessDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalWitnessDraft) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional witness draft.
    final class RegionalWitnessDraftValidator {
        var rules: [any RegionalWitnessDraftRule]

        init(rules: [any RegionalWitnessDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalWitnessDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalWitnessDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalWitnessDraft]) -> [String: [String]] {
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

    static func defaultRegionalWitnessDraftValidator() -> RegionalWitnessDraftValidator {
        return RegionalWitnessDraftValidator(
            rules: [
                RegionalWitnessDraftRequiredLabelRule(message: "regional witness draft needs an entry"),
                RegionalWitnessDraftCodePrefixRule(prefix: "Q"),
                RegionalWitnessDraftCodeLengthRule(maxLength: 120),
                RegionalWitnessDraftEndsAtRangeRule(min: 1000, max: 86400),
            ]
        )
    }
}
