import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped statement threshold must pass. Check returns its problems, or none.
    protocol CappedStatementThresholdRule {
        func check(_ item: CappedStatementThreshold) -> [String]
    }

    final class CappedStatementThresholdCodeLengthRule: CappedStatementThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedStatementThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedStatementThresholdBedLengthRule: CappedStatementThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedStatementThreshold) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedStatementThresholdCodePrefixRule: CappedStatementThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedStatementThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedStatementThresholdRequiredCodeRule: CappedStatementThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedStatementThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped statement threshold.
    final class CappedStatementThresholdValidator {
        var rules: [any CappedStatementThresholdRule]

        init(rules: [any CappedStatementThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedStatementThreshold) -> [String] {
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

        func requireValid(_ item: CappedStatementThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedStatementThreshold]) -> [String: [String]] {
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

    static func defaultCappedStatementThresholdValidator() -> CappedStatementThresholdValidator {
        return CappedStatementThresholdValidator(
            rules: [
                CappedStatementThresholdCodeLengthRule(maxLength: 120),
                CappedStatementThresholdBedLengthRule(maxLength: 120),
                CappedStatementThresholdCodePrefixRule(prefix: "Q"),
                CappedStatementThresholdRequiredCodeRule(message: "capped statement threshold needs an entry"),
            ]
        )
    }
}
