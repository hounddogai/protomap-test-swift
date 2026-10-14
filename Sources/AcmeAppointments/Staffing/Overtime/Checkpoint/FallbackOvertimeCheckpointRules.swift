import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback overtime checkpoint must pass. Check returns its problems, or none.
    protocol FallbackOvertimeCheckpointRule {
        func check(_ item: FallbackOvertimeCheckpoint) -> [String]
    }

    final class FallbackOvertimeCheckpointRequiredCodeRule: FallbackOvertimeCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOvertimeCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackOvertimeCheckpointCodePrefixRule: FallbackOvertimeCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackOvertimeCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackOvertimeCheckpointRequiredTitleRule: FallbackOvertimeCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOvertimeCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackOvertimeCheckpointCodeLengthRule: FallbackOvertimeCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackOvertimeCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback overtime checkpoint.
    final class FallbackOvertimeCheckpointValidator {
        var rules: [any FallbackOvertimeCheckpointRule]

        init(rules: [any FallbackOvertimeCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackOvertimeCheckpoint) -> [String] {
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

        func requireValid(_ item: FallbackOvertimeCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackOvertimeCheckpoint]) -> [String: [String]] {
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

    static func defaultFallbackOvertimeCheckpointValidator() -> FallbackOvertimeCheckpointValidator {
        return FallbackOvertimeCheckpointValidator(
            rules: [
                FallbackOvertimeCheckpointRequiredCodeRule(message: "fallback overtime checkpoint needs this field"),
                FallbackOvertimeCheckpointCodePrefixRule(prefix: "ACM"),
                FallbackOvertimeCheckpointRequiredTitleRule(message: "fallback overtime checkpoint needs a value"),
                FallbackOvertimeCheckpointCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
