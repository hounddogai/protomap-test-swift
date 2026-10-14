import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled reference range baseline must pass. Check returns its problems, or none.
    protocol ScheduledReferenceRangeBaselineRule {
        func check(_ item: ScheduledReferenceRangeBaseline) -> [String]
    }

    final class ScheduledReferenceRangeBaselineRequiredLabelRule: ScheduledReferenceRangeBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledReferenceRangeBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledReferenceRangeBaselineLimitRangeRule: ScheduledReferenceRangeBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledReferenceRangeBaseline) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledReferenceRangeBaselineLabelLengthRule: ScheduledReferenceRangeBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledReferenceRangeBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledReferenceRangeBaselineCodePrefixRule: ScheduledReferenceRangeBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledReferenceRangeBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledReferenceRangeBaselineRequiredSegmentRule: ScheduledReferenceRangeBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledReferenceRangeBaseline) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled reference range baseline.
    final class ScheduledReferenceRangeBaselineValidator {
        var rules: [any ScheduledReferenceRangeBaselineRule]

        init(rules: [any ScheduledReferenceRangeBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledReferenceRangeBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledReferenceRangeBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledReferenceRangeBaseline]) -> [String: [String]] {
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

    static func defaultScheduledReferenceRangeBaselineValidator() -> ScheduledReferenceRangeBaselineValidator {
        return ScheduledReferenceRangeBaselineValidator(
            rules: [
                ScheduledReferenceRangeBaselineRequiredLabelRule(
                    message: "scheduled reference range baseline needs a value"
                ),
                ScheduledReferenceRangeBaselineLimitRangeRule(min: 32, max: 80),
                ScheduledReferenceRangeBaselineLabelLengthRule(maxLength: 3600),
                ScheduledReferenceRangeBaselineCodePrefixRule(prefix: "Q"),
                ScheduledReferenceRangeBaselineRequiredSegmentRule(
                    message: "scheduled reference range baseline needs an entry"
                ),
            ]
        )
    }
}
