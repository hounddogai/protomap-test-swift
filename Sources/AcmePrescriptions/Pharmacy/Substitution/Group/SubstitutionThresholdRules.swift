import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution threshold must pass. Check returns its problems, or none.
    protocol SubstitutionThresholdRule {
        func check(_ item: SubstitutionThreshold) -> [String]
    }

    final class SubstitutionThresholdRequiredSourceRule: SubstitutionThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionThreshold) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionThresholdDurationMinutesRangeRule: SubstitutionThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionThreshold) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SubstitutionThresholdRequiredLabelRule: SubstitutionThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionThreshold) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionThresholdRequiredContactEmailRule: SubstitutionThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionThreshold) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionThresholdRequiredCodeRule: SubstitutionThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionThresholdCodePrefixRule: SubstitutionThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SubstitutionThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution threshold.
    final class SubstitutionThresholdValidator {
        var rules: [any SubstitutionThresholdRule]

        init(rules: [any SubstitutionThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionThreshold) -> [String] {
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

        func requireValid(_ item: SubstitutionThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionThreshold]) -> [String: [String]] {
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

    static func defaultSubstitutionThresholdValidator() -> SubstitutionThresholdValidator {
        return SubstitutionThresholdValidator(
            rules: [
                SubstitutionThresholdRequiredSourceRule(message: "substitution threshold needs this field"),
                SubstitutionThresholdDurationMinutesRangeRule(min: 32, max: 80),
                SubstitutionThresholdRequiredLabelRule(message: "substitution threshold needs an entry"),
                SubstitutionThresholdRequiredContactEmailRule(message: "substitution threshold needs a value"),
                SubstitutionThresholdRequiredCodeRule(message: "substitution threshold needs a value"),
                SubstitutionThresholdCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
