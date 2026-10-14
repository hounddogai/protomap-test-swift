import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback courier cycle must pass. Check returns its problems, or none.
    protocol FallbackCourierCycleRule {
        func check(_ item: FallbackCourierCycle) -> [String]
    }

    final class FallbackCourierCycleRequiredNameRule: FallbackCourierCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCourierCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCourierCycleAmountRangeRule: FallbackCourierCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCourierCycle) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackCourierCycleLabelLengthRule: FallbackCourierCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCourierCycle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCourierCycleScoreRangeRule: FallbackCourierCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCourierCycle) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackCourierCycleRequiredCodeRule: FallbackCourierCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCourierCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback courier cycle.
    final class FallbackCourierCycleValidator {
        var rules: [any FallbackCourierCycleRule]

        init(rules: [any FallbackCourierCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCourierCycle) -> [String] {
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

        func requireValid(_ item: FallbackCourierCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCourierCycle]) -> [String: [String]] {
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

    static func defaultFallbackCourierCycleValidator() -> FallbackCourierCycleValidator {
        return FallbackCourierCycleValidator(
            rules: [
                FallbackCourierCycleRequiredNameRule(message: "fallback courier cycle needs an entry"),
                FallbackCourierCycleAmountRangeRule(min: 9.8, max: 4417.6),
                FallbackCourierCycleLabelLengthRule(maxLength: 120),
                FallbackCourierCycleScoreRangeRule(min: 7.7, max: 4321.8),
                FallbackCourierCycleRequiredCodeRule(message: "fallback courier cycle needs a value"),
            ]
        )
    }
}
