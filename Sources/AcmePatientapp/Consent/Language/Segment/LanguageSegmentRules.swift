import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language segment must pass. Check returns its problems, or none.
    protocol LanguageSegmentRule {
        func check(_ item: LanguageSegment) -> [String]
    }

    final class LanguageSegmentThresholdRangeRule: LanguageSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageSegment) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageSegmentRequiredCodeRule: LanguageSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageSegmentCostRangeRule: LanguageSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageSegment) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguageSegmentNameLengthRule: LanguageSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageSegment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageSegmentRequiredNameRule: LanguageSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageSegment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a language segment.
    final class LanguageSegmentValidator {
        var rules: [any LanguageSegmentRule]

        init(rules: [any LanguageSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageSegment) -> [String] {
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

        func requireValid(_ item: LanguageSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageSegment]) -> [String: [String]] {
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

    static func defaultLanguageSegmentValidator() -> LanguageSegmentValidator {
        return LanguageSegmentValidator(
            rules: [
                LanguageSegmentThresholdRangeRule(min: 3.1, max: 1341.0),
                LanguageSegmentRequiredCodeRule(message: "language segment needs this field"),
                LanguageSegmentCostRangeRule(min: 8.2, max: 1315.5),
                LanguageSegmentNameLengthRule(maxLength: 16),
                LanguageSegmentRequiredNameRule(message: "language segment needs this field"),
            ]
        )
    }
}
