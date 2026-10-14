import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled cleaning threshold must pass. Check returns its problems, or none.
    protocol ScheduledCleaningThresholdRule {
        func check(_ item: ScheduledCleaningThreshold) -> [String]
    }

    final class ScheduledCleaningThresholdCodePrefixRule: ScheduledCleaningThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledCleaningThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledCleaningThresholdRequiredNameRule: ScheduledCleaningThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCleaningThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCleaningThresholdRequiredCodeRule: ScheduledCleaningThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCleaningThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCleaningThresholdSegmentLengthRule: ScheduledCleaningThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCleaningThreshold) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCleaningThresholdNameLengthRule: ScheduledCleaningThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCleaningThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled cleaning threshold.
    final class ScheduledCleaningThresholdValidator {
        var rules: [any ScheduledCleaningThresholdRule]

        init(rules: [any ScheduledCleaningThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCleaningThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCleaningThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCleaningThreshold]) -> [String: [String]] {
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

    static func defaultScheduledCleaningThresholdValidator() -> ScheduledCleaningThresholdValidator {
        return ScheduledCleaningThresholdValidator(
            rules: [
                ScheduledCleaningThresholdCodePrefixRule(prefix: "ACM"),
                ScheduledCleaningThresholdRequiredNameRule(message: "scheduled cleaning threshold needs a value"),
                ScheduledCleaningThresholdRequiredCodeRule(message: "scheduled cleaning threshold needs this field"),
                ScheduledCleaningThresholdSegmentLengthRule(maxLength: 80),
                ScheduledCleaningThresholdNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
