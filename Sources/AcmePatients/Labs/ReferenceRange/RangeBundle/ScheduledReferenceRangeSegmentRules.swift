import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled reference range segment must pass. Check returns its problems, or none.
    protocol ScheduledReferenceRangeSegmentRule {
        func check(_ item: ScheduledReferenceRangeSegment) -> [String]
    }

    final class ScheduledReferenceRangeSegmentCodeLengthRule: ScheduledReferenceRangeSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledReferenceRangeSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledReferenceRangeSegmentDosageMgRangeRule: ScheduledReferenceRangeSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledReferenceRangeSegment) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledReferenceRangeSegmentMaximumRangeRule: ScheduledReferenceRangeSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledReferenceRangeSegment) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledReferenceRangeSegmentRequiredPayerRule: ScheduledReferenceRangeSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledReferenceRangeSegment) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledReferenceRangeSegmentCodePrefixRule: ScheduledReferenceRangeSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledReferenceRangeSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled reference range segment.
    final class ScheduledReferenceRangeSegmentValidator {
        var rules: [any ScheduledReferenceRangeSegmentRule]

        init(rules: [any ScheduledReferenceRangeSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledReferenceRangeSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledReferenceRangeSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledReferenceRangeSegment]) -> [String: [String]] {
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

    static func defaultScheduledReferenceRangeSegmentValidator() -> ScheduledReferenceRangeSegmentValidator {
        return ScheduledReferenceRangeSegmentValidator(
            rules: [
                ScheduledReferenceRangeSegmentCodeLengthRule(maxLength: 1000),
                ScheduledReferenceRangeSegmentDosageMgRangeRule(min: 0.2, max: 4337.5),
                ScheduledReferenceRangeSegmentMaximumRangeRule(min: 6.7, max: 1086.2),
                ScheduledReferenceRangeSegmentRequiredPayerRule(
                    message: "scheduled reference range segment needs a value"
                ),
                ScheduledReferenceRangeSegmentCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
