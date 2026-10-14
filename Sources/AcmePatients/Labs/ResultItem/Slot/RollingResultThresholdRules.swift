import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling result threshold must pass. Check returns its problems, or none.
    protocol RollingResultThresholdRule {
        func check(_ item: RollingResultThreshold) -> [String]
    }

    final class RollingResultThresholdRequiredCodeRule: RollingResultThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingResultThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingResultThresholdNameLengthRule: RollingResultThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingResultThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingResultThresholdRequiredNameRule: RollingResultThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingResultThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingResultThresholdRequiredTimezoneRule: RollingResultThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingResultThreshold) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingResultThresholdRequiredBedRule: RollingResultThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingResultThreshold) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling result threshold.
    final class RollingResultThresholdValidator {
        var rules: [any RollingResultThresholdRule]

        init(rules: [any RollingResultThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingResultThreshold) -> [String] {
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

        func requireValid(_ item: RollingResultThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingResultThreshold]) -> [String: [String]] {
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

    static func defaultRollingResultThresholdValidator() -> RollingResultThresholdValidator {
        return RollingResultThresholdValidator(
            rules: [
                RollingResultThresholdRequiredCodeRule(message: "rolling result threshold needs this field"),
                RollingResultThresholdNameLengthRule(maxLength: 16),
                RollingResultThresholdRequiredNameRule(message: "rolling result threshold needs this field"),
                RollingResultThresholdRequiredTimezoneRule(message: "rolling result threshold needs a value"),
                RollingResultThresholdRequiredBedRule(message: "rolling result threshold needs an entry"),
            ]
        )
    }
}
