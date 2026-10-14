import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense score must pass. Check returns its problems, or none.
    protocol DispenseScoreRule {
        func check(_ item: DispenseScore) -> [String]
    }

    final class DispenseScoreRequiredCodeRule: DispenseScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseScoreMarginRangeRule: DispenseScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseScore) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DispenseScoreExpiresAtRangeRule: DispenseScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseScore) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DispenseScoreRateRangeRule: DispenseScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseScore) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseScoreCountryLengthRule: DispenseScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseScore) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseScoreRequiredRegionRule: DispenseScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseScore) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a dispense score.
    final class DispenseScoreValidator {
        var rules: [any DispenseScoreRule]

        init(rules: [any DispenseScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseScore) -> [String] {
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

        func requireValid(_ item: DispenseScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseScore]) -> [String: [String]] {
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

    static func defaultDispenseScoreValidator() -> DispenseScoreValidator {
        return DispenseScoreValidator(
            rules: [
                DispenseScoreRequiredCodeRule(message: "dispense score needs this field"),
                DispenseScoreMarginRangeRule(min: 1.7, max: 3829.2),
                DispenseScoreExpiresAtRangeRule(min: 120, max: 86400),
                DispenseScoreRateRangeRule(min: 5.3, max: 2556.5),
                DispenseScoreCountryLengthRule(maxLength: 1000),
                DispenseScoreRequiredRegionRule(message: "dispense score needs a value"),
            ]
        )
    }
}
