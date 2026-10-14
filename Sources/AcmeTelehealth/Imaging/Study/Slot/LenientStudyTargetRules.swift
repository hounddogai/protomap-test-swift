import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a lenient study target must pass. Check returns its problems, or none.
    protocol LenientStudyTargetRule {
        func check(_ item: LenientStudyTarget) -> [String]
    }

    final class LenientStudyTargetRequiredNameRule: LenientStudyTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientStudyTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientStudyTargetRateRangeRule: LenientStudyTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientStudyTarget) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientStudyTargetNameLengthRule: LenientStudyTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientStudyTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientStudyTargetGraceDaysRangeRule: LenientStudyTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientStudyTarget) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientStudyTargetCostRangeRule: LenientStudyTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientStudyTarget) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient study target.
    final class LenientStudyTargetValidator {
        var rules: [any LenientStudyTargetRule]

        init(rules: [any LenientStudyTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientStudyTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientStudyTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientStudyTarget]) -> [String: [String]] {
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

    static func defaultLenientStudyTargetValidator() -> LenientStudyTargetValidator {
        return LenientStudyTargetValidator(
            rules: [
                LenientStudyTargetRequiredNameRule(message: "lenient study target needs this field"),
                LenientStudyTargetRateRangeRule(min: 7.8, max: 2905.6),
                LenientStudyTargetNameLengthRule(maxLength: 80),
                LenientStudyTargetGraceDaysRangeRule(min: 32, max: 80),
                LenientStudyTargetCostRangeRule(min: 5.6, max: 590.5),
            ]
        )
    }
}
