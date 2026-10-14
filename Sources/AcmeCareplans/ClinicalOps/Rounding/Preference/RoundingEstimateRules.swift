import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding estimate must pass. Check returns its problems, or none.
    protocol RoundingEstimateRule {
        func check(_ item: RoundingEstimate) -> [String]
    }

    final class RoundingEstimateRefillsRangeRule: RoundingEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingEstimate) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingEstimateRequiredNameRule: RoundingEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingEstimateCodeLengthRule: RoundingEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingEstimateFloorValueRangeRule: RoundingEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingEstimate) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding estimate.
    final class RoundingEstimateValidator {
        var rules: [any RoundingEstimateRule]

        init(rules: [any RoundingEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingEstimate]) -> [String: [String]] {
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

    static func defaultRoundingEstimateValidator() -> RoundingEstimateValidator {
        return RoundingEstimateValidator(
            rules: [
                RoundingEstimateRefillsRangeRule(min: 3600, max: 86400),
                RoundingEstimateRequiredNameRule(message: "rounding estimate needs an entry"),
                RoundingEstimateCodeLengthRule(maxLength: 3600),
                RoundingEstimateFloorValueRangeRule(min: 5.1, max: 3698.8),
            ]
        )
    }
}
