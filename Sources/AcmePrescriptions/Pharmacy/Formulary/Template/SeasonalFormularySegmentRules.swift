import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a seasonal formulary segment must pass. Check returns its problems, or none.
    protocol SeasonalFormularySegmentRule {
        func check(_ item: SeasonalFormularySegment) -> [String]
    }

    final class SeasonalFormularySegmentRequiredCodeRule: SeasonalFormularySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalFormularySegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalFormularySegmentLabelLengthRule: SeasonalFormularySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalFormularySegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalFormularySegmentCeilingRangeRule: SeasonalFormularySegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalFormularySegment) -> [String] {
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

    /// Runs every rule of a seasonal formulary segment.
    final class SeasonalFormularySegmentValidator {
        var rules: [any SeasonalFormularySegmentRule]

        init(rules: [any SeasonalFormularySegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalFormularySegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalFormularySegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalFormularySegment]) -> [String: [String]] {
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

    static func defaultSeasonalFormularySegmentValidator() -> SeasonalFormularySegmentValidator {
        return SeasonalFormularySegmentValidator(
            rules: [
                SeasonalFormularySegmentRequiredCodeRule(message: "seasonal formulary segment needs this field"),
                SeasonalFormularySegmentLabelLengthRule(maxLength: 86400),
                SeasonalFormularySegmentCeilingRangeRule(min: 0.1, max: 1934.2),
            ]
        )
    }
}
