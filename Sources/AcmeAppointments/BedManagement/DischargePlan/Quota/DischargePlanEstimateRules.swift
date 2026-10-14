import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan estimate must pass. Check returns its problems, or none.
    protocol DischargePlanEstimateRule {
        func check(_ item: DischargePlanEstimate) -> [String]
    }

    final class DischargePlanEstimateScoreRangeRule: DischargePlanEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanEstimate) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DischargePlanEstimateCodeLengthRule: DischargePlanEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanEstimateVisitMinutesRangeRule: DischargePlanEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanEstimate) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DischargePlanEstimateRequiredTitleRule: DischargePlanEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanEstimateAllowedExternalRefRule: DischargePlanEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan estimate.
    final class DischargePlanEstimateValidator {
        var rules: [any DischargePlanEstimateRule]

        init(rules: [any DischargePlanEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanEstimate) -> [String] {
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

        func requireValid(_ item: DischargePlanEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanEstimate]) -> [String: [String]] {
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

    static func defaultDischargePlanEstimateValidator() -> DischargePlanEstimateValidator {
        return DischargePlanEstimateValidator(
            rules: [
                DischargePlanEstimateScoreRangeRule(min: 0.5, max: 588.0),
                DischargePlanEstimateCodeLengthRule(maxLength: 32),
                DischargePlanEstimateVisitMinutesRangeRule(min: 80, max: 3600),
                DischargePlanEstimateRequiredTitleRule(message: "discharge plan estimate needs an entry"),
                DischargePlanEstimateAllowedExternalRefRule(allowed: ["primary", "fallback"]),
            ]
        )
    }
}
