import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen cycle must pass. Check returns its problems, or none.
    protocol SpecimenCycleRule {
        func check(_ item: SpecimenCycle) -> [String]
    }

    final class SpecimenCycleScoreRangeRule: SpecimenCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenCycle) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenCycleCodePrefixRule: SpecimenCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SpecimenCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SpecimenCycleRatioRangeRule: SpecimenCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenCycle) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SpecimenCycleRequiredCountryRule: SpecimenCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenCycle) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenCycleActiveGuardRule: SpecimenCycleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SpecimenCycle) -> [String] {
            if item.active && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class SpecimenCycleCurrencyLengthRule: SpecimenCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenCycle) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen cycle.
    final class SpecimenCycleValidator {
        var rules: [any SpecimenCycleRule]

        init(rules: [any SpecimenCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenCycle) -> [String] {
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

        func requireValid(_ item: SpecimenCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenCycle]) -> [String: [String]] {
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

    static func defaultSpecimenCycleValidator() -> SpecimenCycleValidator {
        return SpecimenCycleValidator(
            rules: [
                SpecimenCycleScoreRangeRule(min: 7.6, max: 1668.5),
                SpecimenCycleCodePrefixRule(prefix: "OPS"),
                SpecimenCycleRatioRangeRule(min: 7.4, max: 1632.3),
                SpecimenCycleRequiredCountryRule(message: "specimen cycle needs this field"),
                SpecimenCycleActiveGuardRule(limit: 1.1),
                SpecimenCycleCurrencyLengthRule(maxLength: 255),
            ]
        )
    }
}
