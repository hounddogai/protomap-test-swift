import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy statement threshold must pass. Check returns its problems, or none.
    protocol LegacyStatementThresholdRule {
        func check(_ item: LegacyStatementThreshold) -> [String]
    }

    final class LegacyStatementThresholdRequiredDescriptionRule: LegacyStatementThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyStatementThreshold) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyStatementThresholdRequiredCodeRule: LegacyStatementThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyStatementThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyStatementThresholdRequiredClinicianIDRule: LegacyStatementThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyStatementThreshold) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyStatementThresholdLabelLengthRule: LegacyStatementThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyStatementThreshold) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyStatementThresholdExpiresAtRangeRule: LegacyStatementThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyStatementThreshold) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyStatementThresholdCodePrefixRule: LegacyStatementThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyStatementThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy statement threshold.
    final class LegacyStatementThresholdValidator {
        var rules: [any LegacyStatementThresholdRule]

        init(rules: [any LegacyStatementThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyStatementThreshold) -> [String] {
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

        func requireValid(_ item: LegacyStatementThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyStatementThreshold]) -> [String: [String]] {
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

    static func defaultLegacyStatementThresholdValidator() -> LegacyStatementThresholdValidator {
        return LegacyStatementThresholdValidator(
            rules: [
                LegacyStatementThresholdRequiredDescriptionRule(message: "legacy statement threshold needs an entry"),
                LegacyStatementThresholdRequiredCodeRule(message: "legacy statement threshold needs an entry"),
                LegacyStatementThresholdRequiredClinicianIDRule(message: "legacy statement threshold needs a value"),
                LegacyStatementThresholdLabelLengthRule(maxLength: 16),
                LegacyStatementThresholdExpiresAtRangeRule(min: 1000, max: 1000),
                LegacyStatementThresholdCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
