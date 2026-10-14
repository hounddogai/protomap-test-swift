import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a strict substitution threshold must pass. Check returns its problems, or none.
    protocol StrictSubstitutionThresholdRule {
        func check(_ item: StrictSubstitutionThreshold) -> [String]
    }

    final class StrictSubstitutionThresholdRequiredCodeRule: StrictSubstitutionThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSubstitutionThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSubstitutionThresholdRequiredLabelRule: StrictSubstitutionThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSubstitutionThreshold) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSubstitutionThresholdCodePrefixRule: StrictSubstitutionThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictSubstitutionThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictSubstitutionThresholdCodeLengthRule: StrictSubstitutionThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSubstitutionThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict substitution threshold.
    final class StrictSubstitutionThresholdValidator {
        var rules: [any StrictSubstitutionThresholdRule]

        init(rules: [any StrictSubstitutionThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSubstitutionThreshold) -> [String] {
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

        func requireValid(_ item: StrictSubstitutionThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSubstitutionThreshold]) -> [String: [String]] {
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

    static func defaultStrictSubstitutionThresholdValidator() -> StrictSubstitutionThresholdValidator {
        return StrictSubstitutionThresholdValidator(
            rules: [
                StrictSubstitutionThresholdRequiredCodeRule(message: "strict substitution threshold needs a value"),
                StrictSubstitutionThresholdRequiredLabelRule(
                    message: "strict substitution threshold needs this field"
                ),
                StrictSubstitutionThresholdCodePrefixRule(prefix: "X"),
                StrictSubstitutionThresholdCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
