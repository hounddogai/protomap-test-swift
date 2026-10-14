import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled accession target must pass. Check returns its problems, or none.
    protocol ScheduledAccessionTargetRule {
        func check(_ item: ScheduledAccessionTarget) -> [String]
    }

    final class ScheduledAccessionTargetRequiredSegmentRule: ScheduledAccessionTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAccessionTarget) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAccessionTargetCeilingRangeRule: ScheduledAccessionTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledAccessionTarget) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledAccessionTargetLabelLengthRule: ScheduledAccessionTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAccessionTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledAccessionTargetMaximumRangeRule: ScheduledAccessionTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledAccessionTarget) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled accession target.
    final class ScheduledAccessionTargetValidator {
        var rules: [any ScheduledAccessionTargetRule]

        init(rules: [any ScheduledAccessionTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledAccessionTarget) -> [String] {
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

        func requireValid(_ item: ScheduledAccessionTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledAccessionTarget]) -> [String: [String]] {
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

    static func defaultScheduledAccessionTargetValidator() -> ScheduledAccessionTargetValidator {
        return ScheduledAccessionTargetValidator(
            rules: [
                ScheduledAccessionTargetRequiredSegmentRule(message: "scheduled accession target needs a value"),
                ScheduledAccessionTargetCeilingRangeRule(min: 3.8, max: 2513.8),
                ScheduledAccessionTargetLabelLengthRule(maxLength: 80),
                ScheduledAccessionTargetMaximumRangeRule(min: 8.8, max: 3566.3),
            ]
        )
    }
}
